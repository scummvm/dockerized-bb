#include "romfs.h"
#include "datatypes.h"
#include "n64utils.h"
#include "PI.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
#include <unistd.h>

#define FROM_BE_32(a) a
#define FROM_BE_16(a) a

#define MAX(x, y)	((x) > (y) ? (x) : (y))
#define MIN(x, y)	((x) < (y) ? (x) : (y))

inline Uint32 SWAP_BYTES_32(Uint32 a) {
	const Uint16 low = (Uint16)a, high = (Uint16)(a >> 16);
	return ((Uint32)(Uint16)((low >> 8) | (low << 8)) << 16) | (Uint16)((high >> 8) | (high << 8));
}

inline Uint16 SWAP_BYTES_16(const Uint16 a) {
	return (a >> 8) | (a << 8);
}

// File types
#define isHard(type)    (type == 0)
#define isDir(type)     (type == 1)
#define isRegular(type) (type == 2)

typedef struct {
	Uint32 next_offset; // The last four bits are used for mode of current file
	Uint32 spec;
	Uint32 size; // Bytes
	Uint32 checksum;
	char filename[MAX_FILENAME_LEN];
} file_header;

static Uint8 *romfs_pointer = NULL;
static Uint8 *root_header = NULL; // First header of the list...
static fs_header header;

#define MAX_TOK_SIZE 64
#define MAX_PATH_TOK 50
static char cwdDirPath[MAX_PATH_TOK][MAX_TOK_SIZE];
static Uint8 currentTokenPath;

//static N64Mutex *mtx;

/**** PRIVATE FUNCTIONS ****/

// Searches the file header of a given filename inside a directory
// This is performed by givin in input the address of header of the first file inside that directory,
// the function will then iterate through the list until it finds the file, or until the
// list ends.
// If the file is found, the address of header is returned, otherwise the function returns NULL
Uint8* search_file_header(Uint8* start, const char* path);

// Crawls a path and returns the header address of the given file, be it a directory, a normal file or anything
// NOTE: It starts searching from the CURRENT WORKING DIR
Uint8* crawl_directory_path(const char *name);

// Returns the Uint8 containing file type informations
Uint8 getType(file_header* fhead);

// Updates the tokens used to reconstruct the current path
void update_cwd_path(const char *path);

// Changes the filepath in the buffer, removing ".." and "."
void normalize_path(char *path, Uint32 size);

// Calculate filename size (on romfs it's padded to 16 bytes)
int calculateFilenameLength(char *filename_begin);

int calculateFilenameLength(char *filename_begin) {
	int size = 0;

	int i = 0;
	while (filename_begin[i] != '\0' && size < MAX_FILENAME_LEN) {
		size++;
		i++;
	}

	size = size - (size % 16) + (size % 16 ? 16 : 0);

	return size;
}

void normalize_path(char *path, Uint32 size) {

	if (size == 0 || path == NULL) return;

	char tmpDirPath[MAX_PATH_TOK][MAX_TOK_SIZE];
	Uint8 tmpToken = 0;

	char *path_token = (char*)strtok(path, "/");

	while (path_token != NULL) {
		if (strncmp(path_token, ".", 2) == 0) { } // Nothing to do...
		else if (strncmp(path_token, "..", 2) == 0) { // Previous dir
			if (tmpToken > 0) tmpToken--;
		} else {
			memset(tmpDirPath[tmpToken], 0, MAX_TOK_SIZE);
			snprintf(tmpDirPath[tmpToken], MAX_TOK_SIZE, "%s", path_token);
			tmpToken++;
		}
		path_token = (char*)strtok(NULL, "/");
	}

	memset(path, 0, size);
	Uint32 remaining = size - 1;

	if (!remaining) return;
	sprintf(path, "/");
	remaining--;

	Uint32 token;

	for (token = 0; token < tmpToken; token++) {
		if (!(remaining - strlen(tmpDirPath[token]) - 1)) return;

		strcat(path, tmpDirPath[token]);
		remaining -= strlen(tmpDirPath[token]);

		if (token < (tmpToken - 1)) {
			strcat(path, "/");
			remaining -= 1;
		}
	}

}

Uint8* search_file_header(Uint8* start, const char* name) {
	file_header fhead;

	Uint8 *fh = start;
	PI_SafeDMAFromCart(&fhead, fh, sizeof(file_header));

	do {
		if (strcmp(fhead.filename, name) == 0) {
			return fh;
		}

		if (!(FROM_BE_32(fhead.next_offset) & 0xFFFFFFF0)) break;

		fh = romfs_pointer + (FROM_BE_32(fhead.next_offset) & 0xFFFFFFF0);
		PI_SafeDMAFromCart(&fhead, fh, sizeof(file_header));
	} while (1);

	return NULL;
}

void update_cwd_path(const char *path) {
	if (path == NULL) return;

	char pathbuf[512];
	memset(pathbuf, 0, 512);
	memcpy(pathbuf, path, strlen(path));

	if (path[0] == '/') // This is an absolute address
		currentTokenPath = 0;

	char *path_token = (char*)strtok(pathbuf, "/");

	while (path_token != NULL) {
		if (strncmp(path_token, ".", 2) == 0) { } // Nothing to do...
		else if (strncmp(path_token, "..", 2) == 0) { // Previous dir
			if (currentTokenPath > 0) currentTokenPath--;
		} else {
			memset(cwdDirPath[currentTokenPath], 0, MAX_TOK_SIZE);
			snprintf(cwdDirPath[currentTokenPath], MAX_TOK_SIZE, "%s", path_token);
			currentTokenPath++;
		}
		path_token = (char*)strtok(NULL, "/");
	}
}

Uint8* crawl_directory_path(const char *path) {
	Uint16 tokens = 0;

	if (path == NULL) return NULL;

	char pathbuf[512];
	memset(pathbuf, 0, 512);

	if (path[0] != '\0')
		romfs_getcwd(pathbuf, 512);

	strcat(pathbuf, path);

	normalize_path(pathbuf, 512);

	// ROOT PATH!
	if (strcmp(pathbuf, "/") == 0) return root_header;

	if ((char*)strtok(pathbuf, "/") != NULL) tokens++; // it's not an empty path...
	else return NULL;
	while ((char*)strtok(NULL, "/") != NULL) tokens++; // count remaining

	// Prepare the first file header, where we will start the search from
	file_header fhead;

	Uint8 *start_offset = NULL;

	start_offset = root_header;

	PI_SafeDMAFromCart(&fhead, start_offset, sizeof(file_header));

	memset(pathbuf, 0, 512);

	if (path[0] != '\0')
		romfs_getcwd(pathbuf, 512);

	strcat(pathbuf, path);

	normalize_path(pathbuf, 512);

	char *path_token = (char*)strtok(pathbuf, "/");
	while (tokens--) {
		start_offset = search_file_header(start_offset, path_token);

		if (start_offset == NULL) return NULL;

		PI_SafeDMAFromCart(&fhead, start_offset, sizeof(file_header));

		if ((isDir(getType(&fhead)) || isHard(getType(&fhead))) && tokens) { // It's a dir, and we still have got tokens left
			Uint32 fileOff = (FROM_BE_32(fhead.spec) & 0xFFFFFFF0);
			start_offset = romfs_pointer + fileOff;
		} else if (!tokens) { // Found!
			break;
		}

		path_token = (char*)strtok(NULL, "/");
		if (path_token == NULL) return NULL;
	}

	return start_offset;
}

Uint8 getType(file_header* fhead) {
	return (FROM_BE_32(fhead->next_offset) & 0x07);
}

int romfs_close(ROMFILE *fp) {
	if (fp) {
#ifdef ROMFS_BUFFER
		free(fp->dma_buffer);
#endif
		free(fp); // Not much to do, we just have to free the memory
	} else return 0;

	return 1;
}

/**** END OF PRIVATE ****/

void initRomFSmanager(Uint8 *ptr) {
	romfs_pointer = ptr;
	root_header = ptr + sizeof(fs_header);

	//mtx = createN64Mutex();

	memset(cwdDirPath, 0, MAX_PATH_TOK * MAX_TOK_SIZE);
	currentTokenPath = 0;

	// Prepare header in memory
	PI_SafeDMAFromCart(&header, ptr, sizeof(fs_header));

	return;
}

fs_header* getFSHeader(void) {
	return &header;
}

int romfs_chdir(const char *path) {
	file_header fhead;

	Uint8 *file_offset = crawl_directory_path(path);

	if (!file_offset) return -1;

	PI_SafeDMAFromCart(&fhead, file_offset, sizeof(file_header));

	if (!isDir(getType(&fhead)) && !isHard(getType(&fhead))) return -1;

	Uint32 fileOff = (FROM_BE_32(fhead.spec) & 0xFFFFFFF0);

	update_cwd_path(path);

	return 0;
}

char *romfs_getcwd(char *buf, Uint32 size) {
	Uint32 token;
	Uint32 remaining = size - 1;

	memset(buf, 0, size);

	if (!remaining) return NULL;
	sprintf(buf, "/");
	remaining--;

	for (token = 0; token < currentTokenPath; token++) {
		if (!(remaining - strlen(cwdDirPath[token]) - 1)) return NULL;

		strcat(buf, cwdDirPath[token]);
		strcat(buf, "/");
		remaining -= strlen(cwdDirPath[token]) + 1;
	}

	return buf;
}

ROMDIR *romfs_opendir(const char *path) {
	file_header fhead;
	Uint8 *file_offset = crawl_directory_path(path);

	if (!file_offset) return NULL;

	PI_SafeDMAFromCart(&fhead, file_offset, sizeof(file_header));

	// Hard link is for "." and ".."
	if (!isDir(getType(&fhead)) && !isHard(getType(&fhead))) return NULL;

	ROMDIR *dp = memalign(8, sizeof(ROMDIR));
	memset(dp, 0, sizeof(ROMDIR));

	strncpy(dp->dirname, fhead.filename, MAX_FILENAME_LEN - 1);

	dp->ptr_dir = file_offset;
	dp->ptr_files = romfs_pointer + (FROM_BE_32(fhead.spec) & 0xFFFFFFF0);

	dp->entry = 0;

	return dp;
}

int romfs_closedir(ROMDIR *dirp) {
	if (!dirp) return -1;

	free(dirp);

	return 0;
}

void romfs_rewinddir(ROMDIR *dirp) {
	if (!dirp) return;

	dirp->entry = 0; // That's it...
}

romfs_dirent *romfs_readdir(ROMDIR *dirp) {
	if (!dirp) return NULL;
	if (dirp->entry < 0) return NULL;

	file_header fhead;
	Uint8 *fh = dirp->ptr_files;
	Sint16 remaining_entries = dirp->entry;

	PI_SafeDMAFromCart(&fhead, fh, sizeof(file_header));

	while (remaining_entries--) {
		if (!(FROM_BE_32(fhead.next_offset) & 0xFFFFFFF0)) {
			dirp->entry = -1;
			return NULL;
		}

		fh = romfs_pointer + (FROM_BE_32(fhead.next_offset) & 0xFFFFFFF0);
		PI_SafeDMAFromCart(&fhead, fh, sizeof(file_header));
	}

	dirp->entry++;

	romfs_dirent *dirent = memalign(8, sizeof(romfs_dirent));
	memset(dirent, 0, sizeof(romfs_dirent));

	strncpy(dirent->entryname, fhead.filename, MAX_FILENAME_LEN - 1);

	dirent->ptr_entry = fh;
	dirent->type = getType(&fhead);

	return dirent;
}

ROMFILE *romfs_open(const char *path, const char *mode) {
	if (strstr(mode, "w")) return NULL;

	//lockN64Mutex(mtx);

	file_header fhead;
	Uint8 *file_offset = crawl_directory_path(path);

	if (!file_offset) {
		//unlockN64Mutex(mtx);
		return NULL;
	}

	PI_SafeDMAFromCart(&fhead, file_offset, sizeof(file_header));

	if (!isRegular(getType(&fhead))) {
		//unlockN64Mutex(mtx);
		return NULL;
	}


	ROMFILE *fp = memalign(8, sizeof(ROMFILE));
	memset(fp, 0, sizeof(ROMFILE));

	fp->size = FROM_BE_32(fhead.size);
	fp->type = getType(&fhead);
	fp->offset = 0;

	strncpy(fp->filename, fhead.filename, MAX_FILENAME_LEN - 1);

	int name_field_size = calculateFilenameLength(fhead.filename);
	fp->ptr = file_offset + sizeof(file_header) - MAX_FILENAME_LEN + name_field_size; // Start of file data

	fp->eof = 0;
	fp->err = 0;

#ifdef ROMFS_BUFFER
	fp->dma_buffer = memalign(8, ROMFS_BUFFER_SIZE);
	fp->buffer_offset = 0;

	PI_SafeDMAFromCart(fp->dma_buffer, fp->ptr, MIN(ROMFS_BUFFER_SIZE, fp->size));
#endif

	//unlockN64Mutex(mtx);

	return fp;
};

int	romfs_seek(ROMFILE *stream, long offset, int whence) {
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

long romfs_tell(ROMFILE *stream) {
	if (stream == NULL)
		return -1;

	return stream->offset;
}

Uint32 romfs_read(void *ptr, Uint32 size, Uint32 nmemb, ROMFILE *stream) {
	if (ptr == NULL || stream == NULL) return 0; // nothing to do then
	if (size == 0 || nmemb == 0) return 0;
	if (stream->eof || stream->err) return 0;

	Sint32 toRead = size * nmemb;

	if (stream->offset >= stream->size) {
		stream->eof = 1;
		return 0;
	}

	//lockN64Mutex(mtx);

	if ((stream->offset + toRead) > stream->size) {
		toRead = stream->size - stream->offset;
	}

#ifdef ROMFS_BUFFER
	if ((toRead + (8 - (toRead % 8))) >= ROMFS_BUFFER_SIZE)
		PI_SafeDMAFromCart(ptr, stream->ptr + stream->offset, toRead);
	else {
		if ((stream->buffer_offset <= stream->offset) && ((stream->offset + toRead) < (stream->buffer_offset + ROMFS_BUFFER_SIZE))) // It's in the buffer
			memcpy(ptr, stream->dma_buffer + (stream->offset - stream->buffer_offset), toRead); // Done...
		else {
			// Calculate new buffer offset
			stream->buffer_offset = stream->offset - (stream->offset % 8);
			PI_SafeDMAFromCart(stream->dma_buffer, stream->ptr + stream->buffer_offset, ROMFS_BUFFER_SIZE); // Refill the buffer...
			memcpy(ptr, stream->dma_buffer + (stream->offset - stream->buffer_offset), toRead); // And copy data.
		}
	}
#else
	PI_SafeDMAFromCart(ptr, stream->ptr + stream->offset, toRead);
#endif

	stream->offset += toRead;

	//unlockN64Mutex(mtx);

	return toRead / size;
}

void romfs_clearerr(ROMFILE *stream) {
	if (stream == NULL) return;

	stream->eof = 0;
	stream->err = 0;
}

int romfs_eof(ROMFILE* stream) {
	if (stream == NULL) return 1;

	return stream->eof;
}

int romfs_error(ROMFILE* stream) {
	if (stream == NULL) return 1;

	return stream->err;
}

Sint32 romfs_access(const char *path, Sint32 mode) {
	Uint8 *file = crawl_directory_path(path);

	if (!file) return -1;

	if (mode == R_OK || mode == X_OK || mode == F_OK) return 0;
	else return -1;
}

Uint32 romfs_write(const void *ptr, Uint32 size, Uint32 nmemb, ROMFILE *stream) {
	return 0;
}

Uint32 romfs_flush(ROMFILE *stream) {
	return 0;
}


