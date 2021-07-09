#ifndef __FRAMFS_N64__
#define __FRAMFS_N64__

#ifdef __cplusplus
extern "C" {
#endif

#include "datatypes.h"

#define MAX_FILENAME_LEN 32

	typedef struct {
		char filename[MAX_FILENAME_LEN];
		Uint16 size;
		long offset; // Offset in data
		Uint8 eof, err;
		Uint8 file_data[64 * 1024]; // This contains the actual file data: max 64Kb
		Uint8 write; // 0 if reading, 1 if in write mode
	} FRAMFILE;

// Fake dir structure, framfs has only a single level
	typedef struct {
		char dirname[MAX_FILENAME_LEN];
		Uint16 entrynum; // number of current entry read
	} FRAMDIR;

	typedef struct {
		char entryname[MAX_FILENAME_LEN];
	} framfs_dirent;

	/*** FS ACCESS ***/
	FRAMFILE *framfs_open(const char *path, const char *mode);
	int framfs_close(FRAMFILE *stream);
	void framfs_clearerr(FRAMFILE *stream);
	int framfs_eof(FRAMFILE *stream);
	int framfs_error(FRAMFILE *stream);
	int framfs_seek(FRAMFILE *stream, long offset, int whence);
	long framfs_tell(FRAMFILE *stream);
	Uint32 framfs_flush(FRAMFILE *stream);
	Uint32 framfs_read(void *ptr, Uint32 size, Uint32 nmemb, FRAMFILE *stream);
	Uint32 framfs_write(const void *ptr, Uint32 size, Uint32 nmemb, FRAMFILE *stream);

// -1 if unable to remove a file, 0 otherwise
	int framfs_removeFile(const char *filename);

// Used to list content of pak, there is no real dir structure
	FRAMDIR *framfs_opendir(void);
	int framfs_closedir(FRAMDIR *dirp);
	framfs_dirent *framfs_readdir(FRAMDIR *dirp);
	void framfs_rewinddir(FRAMDIR *dirp);

	/*** BASE ***/
// Returns 1 if formatting was required, else 0.
	Uint8 initFramFS(void);
	void formatFramFS(void);

#ifdef __cplusplus
}
#endif

#endif /* __FRAMFS_N64__ */
