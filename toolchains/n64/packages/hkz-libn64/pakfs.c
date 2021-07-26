#include "pakfs.h"
#include "SI.h"

#include "n64utils.h"

#include "unaligned_data.h"

#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <stdio.h>

// This header must reside at begin of pak image,
// it's needed to check that pak is formatted
typedef struct {
	char signature[10]; // "++ROMFS++", 0 terminated
	Uint16 freeBytes;   // Free bytes available in the image
	Uint16 free_offset; // Offset from beginning of pak_image to free space
} pakfs_header;

typedef struct {
	char filename[MAX_FILENAME_LEN]; // File name, max 31 chars + '\0'
	Uint32 fn_hash;    // 32 bit filename hash, used for search.
	Uint16 file_size;  // Size of file (beginning at the end of header)
	Uint16 next_file;  // Offset to next file (from start of current file header)
} pak_file_header;

static Sint8 loadedPak;

// Check if a file is present in pak.
// Returns 1 if found, 0 otherwise
int fileExists(const char *filename);

static Uint8 *pak_image;
static pakfs_header *filesystem_header;

//static N64Mutex *mtx;

/*** FS ACCESS ***/
PAKFILE *pakfs_open(const char *path, const char *mode) {
	if (!path || !mode || !pak_image) return NULL;

	PAKFILE *pfd;

	Uint8 already_present = fileExists(path);

	if (strstr(mode, "r") && !already_present) return NULL;

	if (strstr(mode, "w")) {
		if (already_present)
			removeFileOnPak(path); // Remove file if already present

		pfd = malloc(sizeof(PAKFILE));
		memset(pfd, 0, sizeof(PAKFILE));

		strncpy(pfd->filename, path, MAX_FILENAME_LEN - 1);
		pfd->offset = 0;
		pfd->write = 1;

		return pfd;
	}

	if (strstr(mode, "r") && already_present) {
		pfd = malloc(sizeof(PAKFILE));
		memset(pfd, 0, sizeof(PAKFILE));

		strncpy(pfd->filename, path, MAX_FILENAME_LEN - 1);
		pfd->offset = 0;

		readFileOnPak(path, &(pfd->size), pfd->file_data);

		return pfd;
	}


	return NULL;
}

int pakfs_close(PAKFILE *stream) {
	if (!stream) return EOF;

	if (stream->write && !pakfs_error(stream)) {
		Uint8 writestatus = writeFileOnPak((const char *)stream->filename, stream->size, stream->file_data);
		if (writestatus != 0) {
			free(stream);
			return EOF;
		}
	}

	free(stream);
	return 0;
}

void pakfs_clearerr(PAKFILE *stream) {
	if (!stream) return;

	stream->err = 0;
	stream->eof = 0;
}

int pakfs_eof(PAKFILE *stream) {
	if (!stream) return 1;

	return stream->eof;
}

int pakfs_error(PAKFILE *stream) {
	if (!stream) return 1;

	return stream->err;
}

int pakfs_seek(PAKFILE *stream, long offset, int whence) {
	if (stream == NULL) return -1;

	switch (whence) {
	case SEEK_SET:
		if (offset < 0 || offset > stream->size) return -1;
		stream->offset = offset;
		stream->eof = 0;
		break;

	case SEEK_CUR:
		if ((offset + stream->offset) > stream->size || (offset + stream->offset) < 0) return -1;
		stream->offset += offset;
		stream->eof = 0;
		break;

	case SEEK_END:
		if (((stream->size + offset) < 0) || ((stream->size + offset) > stream->size)) return -1;
		stream->offset = (stream->size + offset);
		stream->eof = 0;
		break;
	default:
		return -1;
	}

	return stream->offset;
}

long pakfs_tell(PAKFILE *stream) {
	if (stream == NULL)
		return -1;

	return stream->offset;
}

Uint32 pakfs_flush(PAKFILE *stream) {
	return 0;
}

Uint32 pakfs_read(void *ptr, Uint32 size, Uint32 nmemb, PAKFILE *stream) {
	if (!pak_image) return 0;
	if (ptr == NULL || stream == NULL) return 0; // nothing to do then
	if (size == 0 || nmemb == 0) return 0;
	if (stream->eof || stream->err) return 0;

	Sint32 toRead = size * nmemb;

	if (stream->offset >= stream->size) {
		stream->eof = 1;
		return 0;
	}

	if ((stream->offset + toRead) > stream->size) {
		toRead = stream->size - stream->offset;
	}

	memcpy(ptr, &(stream->file_data[stream->offset]), toRead);

	stream->offset += toRead;

	return toRead / size;
}

Uint32 pakfs_write(const void *ptr, Uint32 size, Uint32 nmemb, PAKFILE *stream) {
	if (!pak_image) return 0;
	if (ptr == NULL || stream == NULL) return 0; // nothing to do then
	if (size == 0 || nmemb == 0) return 0;
	if (stream->eof || stream->err) return 0;

	Sint32 toWrite = size * nmemb;

	if (stream->offset >= (32 * 1024)) {
		stream->eof = 1;
		stream->err = 1;
		return 0;
	}

	if ((stream->offset + toWrite) > (32 * 1024)) {
		toWrite = stream->size - stream->offset;
	}

	if ((stream->size + toWrite - (stream->size - stream->offset)) >= filesystem_header->freeBytes) {
		stream->err = 1;
		return 0;
	}

	memcpy(&(stream->file_data[stream->offset]), ptr, toWrite);

	stream->size += toWrite - (stream->size - stream->offset);
	stream->offset += toWrite;

	return toWrite / size;
}

PAKDIR *pakfs_opendir(void) {
	if (!pak_image) return NULL;

	PAKDIR *dp = malloc(sizeof(PAKDIR));

	memset(dp, 0, sizeof(PAKDIR));
	dp->entrynum = 0;

	strncpy(dp->dirname, "/", MAX_FILENAME_LEN - 1);

	return dp;
}

int pakfs_closedir(PAKDIR *dirp) {
	if (!dirp) return -1;

	free(dirp);

	return 0;
}

void pakfs_rewinddir(PAKDIR *dirp) {
	dirp->entrynum = 0;
}

pakfs_dirent *pakfs_readdir(PAKDIR *dirp) {
	if (!dirp || !pak_image) return NULL;

	Uint16 skip = dirp->entrynum;

	Uint16 currentOffset = sizeof(pakfs_header); // Beginning offset
	pak_file_header *current_entry = (pak_file_header*)(pak_image + currentOffset);

	while ((currentOffset != SAFE_READ_UINT16(&(filesystem_header->free_offset))) && skip) {
		currentOffset += SAFE_READ_UINT16(&(current_entry->next_file));
		current_entry = (pak_file_header*)(pak_image + currentOffset);
		skip--;
	}

	if (currentOffset >= SAFE_READ_UINT16(&(filesystem_header->free_offset)))
		return NULL;

	dirp->entrynum++;

	pakfs_dirent *dirent = malloc(sizeof(pakfs_dirent));
	memset(dirent, 0, sizeof(pakfs_dirent));

	strncpy(dirent->entryname, current_entry->filename, MAX_FILENAME_LEN - 1);

	return dirent;
}


/*** BASE PAK MANAGEMENT  ***/

void initPakFs(void) {
	//mtx = createN64Mutex();

	loadedPak = -1;
	pak_image = NULL;
}

int loadPakData(Uint8 pakNo) {
	if (pakNo > 3) return -1; // Wrong channel
	if (identifyPak(pakNo) != 1) return -1; // Wrong or no device

	if (pak_image) {
		memset(pak_image, 0, 32 * 1024); // Clean the previous pak image if present
		// WARNING: unsaved data will be lost!!!
	} else {
		pak_image = memalign(8, 32 * 1024); // Allocate space
	}

	// Read mempak data
	readControllerMemPak(pakNo, pak_image);

	filesystem_header = (pakfs_header*)pak_image; // Link header to beginning of FS
	// Check and format the pak
	if (checkAndFormat(0) < 0) return -1;

	loadedPak = pakNo;

	flushPakData(pakNo);

	return 0;
}

int flushCurrentPakData(void) {
	if (!pak_image) return -1;

	if (loadedPak < 0) return -1; // Wrong channel
	if (identifyPak(loadedPak) != 1) return -1; // Wrong or no device

	if (pak_image)
		writeControllerMemPak(loadedPak, 0x0000, pak_image);
	else
		return -1;

	return 0;
}

int flushPakData(Uint8 pakNo) {
	if (!pak_image) return -1;

	if (pakNo > 3) return -1; // Wrong channel
	if (identifyPak(pakNo) != 1) return -1; // Wrong or no device

	if (pak_image)
		writeControllerMemPak(pakNo, 0x0000, pak_image);
	else
		return -1;

	return 0;
}

int writeFileOnPak(const char *filename, Uint16 size, Uint8 *buf) {
	if (!pak_image || !buf || !filename) return -1;

	//lockN64Mutex(mtx);

	if (fileExists(filename)) { // File is already there!
		removeFileOnPak(filename); // Remove it and continue...
	}

	// TODO: actually we should check if the file is already here and if after removing it we
	// have enough space for saving this... without removing it first!
	if ((size + sizeof(pak_file_header)) >= SAFE_READ_UINT16(&(filesystem_header->freeBytes))) {
		//unlockN64Mutex(mtx);
		return -1;
	}

	Uint8 *entry_begin = pak_image + SAFE_READ_UINT16(&(filesystem_header->free_offset));
	pak_file_header *head = (pak_file_header*)entry_begin;
	entry_begin += sizeof(pak_file_header);

	strncpy(head->filename, filename, MAX_FILENAME_LEN - 1); // Save filename
	SAFE_WRITE_UINT32(&(head->fn_hash), hashString(filename)); // Save hash
	SAFE_WRITE_UINT16(&(head->file_size), size); // Save file size
	SAFE_WRITE_UINT16(&(head->next_file), (sizeof(pak_file_header) + size));

	memcpy(entry_begin, buf, size); // Save the entry

	// Reduce free space
	SAFE_WRITE_UINT16(&(filesystem_header->freeBytes), SAFE_READ_UINT16(&(filesystem_header->freeBytes)) - (size + sizeof(pak_file_header)));
	// Update free space offset
	SAFE_WRITE_UINT16(&(filesystem_header->free_offset), SAFE_READ_UINT16(&(head->next_file)) + SAFE_READ_UINT16(&(filesystem_header->free_offset)));

	//unlockN64Mutex(mtx);

	return 0;
}

int readFileOnPak(const char *filename, Uint16 *size, Uint8 *buf) {
	if (!filename || !size || !buf || !pak_image) return -1;

	//lockN64Mutex(mtx);

	Uint32 file_hash = hashString(filename);

	Uint16 currentOffset = sizeof(pakfs_header);
	pak_file_header *current_entry = (pak_file_header*)(pak_image + currentOffset);

	while (currentOffset != SAFE_READ_UINT16(&(filesystem_header->free_offset))) {
		if (file_hash == SAFE_READ_UINT32(&(current_entry->fn_hash))) {
			memcpy(buf, (Uint8*)((Uint8*)current_entry + sizeof(pak_file_header)), SAFE_READ_UINT16(&(current_entry->file_size)));
			SAFE_WRITE_UINT16(size, SAFE_READ_UINT16(&(current_entry->file_size)));

			//unlockN64Mutex(mtx);
			return 0;
		}

		currentOffset += SAFE_READ_UINT16(&(current_entry->next_file));
		current_entry = (pak_file_header*)(pak_image + currentOffset);
	}

	//unlockN64Mutex(mtx);
	return -1;
}

int removeFileOnPak(const char *filename) {
	if (!filename || !pak_image) return -1;

	//lockN64Mutex(mtx);

	Uint8 file_found = 0;
	Uint16 currentOffset = sizeof(pakfs_header); // Beginning offset
	Uint32 file_hash = hashString(filename);
	pak_file_header *current_entry = (pak_file_header*)(pak_image + currentOffset);
	pak_file_header *next_entry;

	while (currentOffset != SAFE_READ_UINT16(&(filesystem_header->free_offset))) {
		if (file_hash == SAFE_READ_UINT32(&(current_entry->fn_hash))) { // TODO: Maybe better perform a check on the string too?
			file_found = 1;
			break;
		}

		currentOffset += SAFE_READ_UINT16(&(current_entry->next_file));
		current_entry = (pak_file_header*)(pak_image + currentOffset);
	}

	if (!file_found) {
		//unlockN64Mutex(mtx);
		return -1;
	}

	Uint16 nextOffset = SAFE_READ_UINT16(&(current_entry->next_file)) + currentOffset;
	Uint16 remove_file_size = SAFE_READ_UINT16(&(current_entry->file_size)) + sizeof(pak_file_header);

	next_entry = (pak_file_header*)((Uint8*)pak_image + nextOffset);

	// Move the other saves back
	memmove(current_entry, next_entry, (32 * 1024) - nextOffset);

	SAFE_WRITE_UINT16(&(filesystem_header->free_offset), SAFE_READ_UINT16(&(filesystem_header->free_offset)) - remove_file_size);
	SAFE_WRITE_UINT16(&(filesystem_header->freeBytes), SAFE_READ_UINT16(&(filesystem_header->freeBytes)) + remove_file_size);

	//unlockN64Mutex(mtx);

	return 0;
}

int checkAndFormat(Uint8 force) {
	if (!pak_image || !filesystem_header || !pak_image) return -1;

	if (!force && strncmp(filesystem_header->signature, "++ROMFS++", 11) == 0) return 0;

	memset(pak_image, 0, 32 * 1024);

	sprintf(filesystem_header->signature, "%s", "++ROMFS++");
	SAFE_WRITE_UINT16(&(filesystem_header->freeBytes), ((32 * 1024) - sizeof(pakfs_header)));
	SAFE_WRITE_UINT16(&(filesystem_header->free_offset), sizeof(pakfs_header));

	flushPakData(loadedPak);
}

int fileExists(const char *filename) {
	if (!filename || !pak_image) return -1;

	Uint32 file_hash = hashString(filename);

	Uint16 currentOffset = sizeof(pakfs_header);
	pak_file_header *current_entry = (pak_file_header*)(pak_image + currentOffset);

	while (currentOffset != SAFE_READ_UINT16(&(filesystem_header->free_offset))) {
		if (file_hash == SAFE_READ_UINT32(&(current_entry->fn_hash))) {
			return 1;
		}

		currentOffset += SAFE_READ_UINT16(&(current_entry->next_file));
		current_entry = (pak_file_header*)(pak_image + currentOffset);
	}

	return 0;
}

