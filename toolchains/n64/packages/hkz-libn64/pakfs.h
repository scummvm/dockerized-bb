#ifndef __PAKFS_N64__
#define __PAKFS_N64__

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
		Uint8 file_data[32 * 1024]; // This contains the actual file data: max 32Kb
		Uint8 write; // 0 if reading, 1 if in write mode
	} PAKFILE;

// Fake dir structure, pakfs has only a single level
	typedef struct {
		char dirname[MAX_FILENAME_LEN];
		Uint16 entrynum; // number of current entry read
	} PAKDIR;

	typedef struct {
		char entryname[MAX_FILENAME_LEN];
	} pakfs_dirent;

	/*** FS ACCESS ***/
	PAKFILE *pakfs_open(const char *path, const char *mode);
	int pakfs_close(PAKFILE *stream);
	void pakfs_clearerr(PAKFILE *stream);
	int pakfs_eof(PAKFILE *stream);
	int pakfs_error(PAKFILE *stream);
	int pakfs_seek(PAKFILE *stream, long offset, int whence);
	long pakfs_tell(PAKFILE *stream);
	Uint32 pakfs_flush(PAKFILE *stream);
	Uint32 pakfs_read(void *ptr, Uint32 size, Uint32 nmemb, PAKFILE *stream);
	Uint32 pakfs_write(const void *ptr, Uint32 size, Uint32 nmemb, PAKFILE *stream);

// Used to list content of pak, there is no real dir structure
	PAKDIR *pakfs_opendir(void);
	int pakfs_closedir(PAKDIR *dirp);
	pakfs_dirent *pakfs_readdir(PAKDIR *dirp);
	void pakfs_rewinddir(PAKDIR *dirp);


	/*** BASE PAK MANAGEMENT ***/
// Initializes the PakFS
	void initPakFs(void);

// Load data from controller pak 'pakNo'.
// returns 0 if ok, -1 if an error occurred
	int loadPakData(Uint8 pakNo);

// Flush Pak data, saving the current buffer to
// pakNo buffer pak. Returns 0 if ok, -1 if error.
	int flushPakData(Uint8 pakNo);
	int flushCurrentPakData(void);

// Writes a buffer on the pak, identified by string 'filename'.
// Returns 0 if ok, -1 if error.
	int writeFileOnPak(const char *filename, Uint16 size, Uint8 *buf);

// Read a file from pak into a buffer, the buffer must be of a safe size
// to contain the file (a safe size is 32kb). the value of size gets set
// to actual file size.
// Returns 0 if ok, -1 if error.
	int readFileOnPak(const char *filename, Uint16 *size, Uint8 *buf);

// Removes file from controller pak.
// Returns 0 if removed successfully, -1 if error occurred.
	int removeFileOnPak(const char *filename);

// Check if the pointed buffer is formatted as pakfs,
// and if it is not, format it.
// If force is 1, the pak gets formatted regardless of what's
// inside.
// Returns -1 for error, 0 if already formatted, 1 if
// format was performed.
	int checkAndFormat(Uint8 force);

#ifdef __cplusplus
}
#endif

#endif

