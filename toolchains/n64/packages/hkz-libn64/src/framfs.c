#include "framfs.h"
#include "N64FlashRAM.h"
#include "N64sys.h"
#include "n64utils.h"
#include "PI.h"

#include <string.h>
#include <stdio.h>

#define MAX(x, y)	((x) > (y) ? (x) : (y))
#define MIN(x, y)	((x) < (y) ? (x) : (y))

#define BANK_DATA 15315

typedef struct {
	Uint32 signature; // Must be 0x4652414D "FRAM"
	Uint32 filename_hash; // Filename hash, if bank is free this is 0xFFFFFFFF
	char filename[MAX_FILENAME_LEN];
	Uint16 file_size;
	Uint8 file_part; // Last 7 bits is the part of file contained in this bank: 0, 1, etc, first bit tells if it's the last part
	Uint8 data[BANK_DATA]; // Data in this bank
} FRAM_BANK; // First block of each bank

static Uint8 freeBanks;
static Uint32 bank_hash[8];

// -1 if filename doesn't exist, 0 otherwise
Uint8 fileExist(const char *filename);
// -1 if unable to find a free bank, number of free bank otherwise
int searchFreeBank(void);

// -1 if unable to write, 0 otherwise
int framfs_writeFile(const char *filename, Uint16 size, Uint8 *buf);
int framfs_readFile(const char *filename, Uint16 *size, Uint8 *buf);

/*** PUBLIC ***/

void formatFramFS(void) {
	Uint8 bankNo;

	// Erase all the banks
	for (bankNo = 0; bankNo < 8; bankNo++) {
		FRAM_EraseBank(bankNo);
		bank_hash[bankNo] = 0xFFFFFFFF;
	}

	FRAM_BANK *head = malloc(sizeof(FRAM_BANK));
	memset(head, 0xFF, sizeof(FRAM_BANK));
	head->signature = 0x4652414D;

	// Write the banks.
	for (bankNo = 0; bankNo < 8; bankNo++)
		FRAM_WriteBlock((Uint8*)head, bankNo * 128);

	free(head);
}

Uint8 initFramFS(void) {
	PI_Init_SRAM();
	FRAM_Init();

	Uint8 bankNo;

	freeBanks = 8;

	for (bankNo = 0; bankNo < 8; bankNo++) {
		bank_hash[bankNo] = 0xFFFFFFFF;
	}

	FRAM_BANK *head = malloc(sizeof(FRAM_BANK));

	// Read the banks.
	for (bankNo = 0; bankNo < 8; bankNo++) {
		FRAM_ReadBlock((Uint8*)head, bankNo * 128);
		if (head->signature != 0x4652414D) { // FlashRAM not formatted or corrupted
			formatFramFS();
			freeBanks = 8;

			free(head);
			return 1;
		} else {
			if (head->filename_hash != 0xFFFFFFFF) {
				bank_hash[bankNo] = head->filename_hash;
				freeBanks--;
			}
		}
	}

	free(head);
	return 0;
}

FRAMDIR *framfs_opendir(void) {
	FRAMDIR *dp = malloc(sizeof(FRAMDIR));

	memset(dp, 0, sizeof(FRAMDIR));
	dp->entrynum = 0;

	strncpy(dp->dirname, "/", MAX_FILENAME_LEN - 1);

	return dp;
}

int framfs_closedir(FRAMDIR *dirp) {
	if (!dirp) return -1;

	free(dirp);

	return 0;
}

void framfs_rewinddir(FRAMDIR *dirp) {
	dirp->entrynum = 0;
}

framfs_dirent *framfs_readdir(FRAMDIR *dirp) {
	if (!dirp || (freeBanks == 8)) return NULL;

	framfs_dirent *dirent;
	Uint16 skip = dirp->entrynum;
	Uint8 bankNo;

	FRAM_BANK *head = malloc(sizeof(FRAM_BANK));

	for (bankNo = 0; bankNo < 8; bankNo++) {
		FRAM_ReadBlock((Uint8*)head, bankNo * 128);
		if ((head->filename_hash != 0xFFFFFFFF) && ((head->file_part & 0x7F) == 0)) {
			if (!skip) {
				dirent = (framfs_dirent*)malloc(sizeof(framfs_dirent));
				memset(dirent, 0, sizeof(framfs_dirent));
				strncpy(dirent->entryname, head->filename, MAX_FILENAME_LEN - 1);

				dirp->entrynum++;

				free(head);
				return dirent;
			} else {
				skip--;
			}
		}
	}

	free(head);
	return NULL;
}


void framfs_clearerr(FRAMFILE *stream) {
	if (!stream) return;

	stream->err = 0;
	stream->eof = 0;
}

int framfs_eof(FRAMFILE *stream) {
	if (!stream) return 1;

	return stream->eof;
}

int framfs_error(FRAMFILE *stream) {
	if (!stream) return 1;

	return stream->err;
}

int framfs_seek(FRAMFILE *stream, long offset, int whence) {
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

long framfs_tell(FRAMFILE *stream) {
	if (stream == NULL)
		return -1;

	return stream->offset;
}

Uint32 framfs_flush(FRAMFILE *stream) {
	return 0;
}


Uint32 framfs_read(void *ptr, Uint32 size, Uint32 nmemb, FRAMFILE *stream) {
	if (!ptr || !stream) return 0; // nothing to do then
	if (!size || !nmemb) return 0;
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

Uint32 framfs_write(const void *ptr, Uint32 size, Uint32 nmemb, FRAMFILE *stream) {
	if (ptr == NULL || stream == NULL) return 0; // nothing to do then
	if (size == 0 || nmemb == 0) return 0;
	if (stream->eof || stream->err) return 0;

	Sint32 toWrite = size * nmemb;

	if (stream->offset >= (64 * 1024)) {
		stream->eof = 1;
		stream->err = 1;
		return 0;
	}

	if (freeBanks == 0) {
		stream->eof = 1;
		stream->err = 1;
		return 0;
	}

	if ((stream->offset + toWrite) > (64 * 1024)) {
		toWrite = stream->size - stream->offset;
	}

	if (((stream->size + toWrite) - (stream->size - stream->offset)) >= (freeBanks * BANK_DATA)) {
		stream->err = 1;
		return 0;
	}

	memcpy(&(stream->file_data[stream->offset]), ptr, toWrite);

	stream->size += toWrite - (stream->size - stream->offset);
	stream->offset += toWrite;

	return toWrite / size;
}

FRAMFILE *framfs_open(const char *path, const char *mode) {
	if (!path || !mode) return NULL;

	FRAMFILE *ffd;

	Uint8 already_present = fileExist(path);

	if (strstr(mode, "r") && !already_present) return NULL;

	if (strstr(mode, "w")) {
		if (already_present)
			framfs_removeFile(path); // Remove file if already present

		if (freeBanks == 0) return NULL;

		ffd = malloc(sizeof(FRAMFILE));
		memset(ffd, 0, sizeof(FRAMFILE));

		strncpy(ffd->filename, path, MAX_FILENAME_LEN - 1);
		ffd->offset = 0;
		ffd->write = 1;

		return ffd;
	}

	if (strstr(mode, "r") && already_present) {
		ffd = malloc(sizeof(FRAMFILE));
		memset(ffd, 0, sizeof(FRAMFILE));

		strncpy(ffd->filename, path, MAX_FILENAME_LEN - 1);
		ffd->offset = 0;

		framfs_readFile(path, &(ffd->size), ffd->file_data);

		return ffd;
	}

	return NULL;
}

int framfs_close(FRAMFILE *stream) {
	if (!stream) return EOF;

	if (stream->write && !framfs_error(stream)) {
		int writestatus = framfs_writeFile((const char *)stream->filename, stream->size, stream->file_data);
		if (writestatus != 0) {
			free(stream);
			return EOF;
		}
	}

	free(stream);
	return 0;
}

/*** PRIVATE ***/
Uint8 fileExist(const char *filename) {
	if (!filename || (freeBanks == 8)) return 0;

	Uint8 bankNo;
	Uint32 hash = hashString(filename);

	for (bankNo = 0; bankNo < 8; bankNo++) {
		if (bank_hash[bankNo] == hash) return 1;
	}

	return 0;
}

int framfs_removeFile(const char *filename) {
	if (!filename || (freeBanks == 8)) return -1;

	Uint8 bankNo;
	Uint32 hash = hashString(filename);
	int result = -1;

	FRAM_BANK *head = malloc(sizeof(FRAM_BANK));

	for (bankNo = 0; bankNo < 8; bankNo++) {
		if (bank_hash[bankNo] == hash) {
			// Erase and replace the bank with a clean dummy
			FRAM_EraseBank(bankNo);
			bank_hash[bankNo] = 0xFFFFFFFF;

			memset(head, 0xFF, sizeof(FRAM_BANK));
			head->signature = 0x4652414D;
			FRAM_WriteBlock((Uint8*)head, bankNo * 128);

			freeBanks++;

			result = 0;
		}
	}

	free(head);
	return result;
}

int framfs_writeFile(const char *filename, Uint16 size, Uint8 *buf) {
	if (!filename || !buf) return -1;

	Uint16 requiredBanks = (size / BANK_DATA) + ((size % BANK_DATA) ? 1 : 0);

	if (requiredBanks > freeBanks) return -1;
	Uint16 remainingBytes = size;

	int currentBank = 0;
	Uint16 currentPart = 0;

	FRAM_BANK *head = malloc(sizeof(FRAM_BANK));

	while (requiredBanks) {
		currentBank = searchFreeBank();

		if (currentBank < 0) return -1;

		Uint16 copyData = MIN(remainingBytes, BANK_DATA);

		memset(head, 0xFF, sizeof(FRAM_BANK));
		head->signature = 0x4652414D;
		head->file_size = size;
		head->file_part = currentPart;
		if ((requiredBanks - 1) == 0) head->file_part |= 0x80; // Last part

		head->filename_hash = hashString(filename);
		bank_hash[currentBank] = head->filename_hash;

		strncpy(head->filename, filename, MAX_FILENAME_LEN - 1);

		memcpy(head->data, buf + (BANK_DATA * currentPart), copyData);

		remainingBytes -= copyData;
		requiredBanks--;
		currentPart++;
		freeBanks--;

		FRAM_WriteBank((Uint8*)head, currentBank);
	}

	free(head);
	return 0;
}

int framfs_readFile(const char *filename, Uint16 *size, Uint8 *buf) {
	if (!filename || !buf || !size) return -1;

	Uint32 file_hash = hashString(filename);

	Uint8 *data = buf;
	Uint8 copy = 1;

	Uint16 bankNo;
	Uint16 current_part = 0;
	Sint32 remainingBytes = -1;

	FRAM_BANK *head = malloc(sizeof(FRAM_BANK));

	while (copy) {
		for (bankNo = 0; bankNo < 8; bankNo++) {
			FRAM_ReadBlock((Uint8*)head, bankNo * 128);
			if ((head->filename_hash == file_hash) && ((head->file_part & 0x7F) == current_part)) {
				if (head->file_part & 0x80) copy = 0; // This was the last part

				*size = head->file_size;
				if (remainingBytes < 0) remainingBytes = head->file_size;
				Uint16 toCopy = MIN(remainingBytes, BANK_DATA);

				FRAM_ReadBank((Uint8*)head, bankNo);
				memcpy(data, head->data, toCopy);

				data += toCopy;
				remainingBytes -= toCopy;
				current_part++;

				break;
			}
		}
	}

	free(head);
	return 0;
}

int searchFreeBank(void) {
	if (freeBanks == 0) return -1;

	Uint8 bankNo;

	for (bankNo = 0; bankNo < 8; bankNo++) {
		if (bank_hash[bankNo] == 0xFFFFFFFF) return bankNo;
	}

	return -1;
}


