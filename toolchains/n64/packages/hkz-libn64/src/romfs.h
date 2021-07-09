#ifndef __ROMFS_N64__
#define __ROMFS_N64__

#ifdef __cplusplus
extern "C" {
#endif

#include "datatypes.h"

#define ROMFS_BUFFER

#ifdef ROMFS_BUFFER
#define ROMFS_BUFFER_SIZE (1024 * 8)
#endif

#define MAX_FILENAME_LEN 32

	typedef struct {
		char signature[8];
		Uint32 full_size;
		Uint32 checksum; // Checksum of the first 512 bytes
		char volname[16];
	} fs_header;

	typedef struct {
		char filename[MAX_FILENAME_LEN]; // max 63 char + \0
		Uint32 size; // Total size
		Uint8 type; // Type of file: dir, hardlink, etc... (needed?)
		Uint8 *ptr; // Pointer to beginning of file data
		long offset; // Current offset from beginning of data

		Uint8 eof, err;
#ifdef ROMFS_BUFFER
		Uint32 buffer_offset;
		Uint8 *dma_buffer;
#endif
	} ROMFILE;

	typedef struct {
		char dirname[MAX_FILENAME_LEN];
		Uint8 *ptr_dir; // Pointer to dir header
		Uint8 *ptr_files; // Beginning of dir content
		Sint16 entry; // Current entry of the dir, starts from 0, -1 when finished
	} ROMDIR;

	typedef struct {
		char entryname[MAX_FILENAME_LEN];
		Uint8 *ptr_entry; // Pointer to entry header in rom image
		Uint8 type; // Type of entry.
	} romfs_dirent;

// Init the ROMFS file system manager.
// ptr -> pointer to memory zone where the romfs image is stored
	void initRomFSmanager(Uint8 *ptr);

// Return FS header
	fs_header* getFSHeader(void);

// Closes and destroy a ROMFILE stream, freeing the memory
// fp -> pointer to ROMFILE structure, created with open
// return -> 1 if stream is closed successfully, 0 if not
	int romfs_close(ROMFILE *fp);

// Opens a ROMFILE stream for a file located on the romfs filesystem.
// path -> path to the file to open
// return -> stream for opened file
	ROMFILE *romfs_open(const char *path, const char *mode);

// Seeks a ROMFILE stream offset bytes.
// Works (or should work) like fseek(...) call.
	int	romfs_seek(ROMFILE *stream, long offset, int whence);

// Works like ftell(...), obtains the current value  of  the
// file position indicator.
	long romfs_tell(ROMFILE *stream);

// Works like fread(...)
	Uint32 romfs_read(void *ptr, Uint32 size, Uint32 nmemb, ROMFILE *stream);

	void romfs_clearerr(ROMFILE *stream);
	int romfs_eof(ROMFILE* stream);
	int romfs_error(ROMFILE* stream);

// Changes current working directory
// Returns 0 if ok, -1 if unable to change dir
	int romfs_chdir(const char *path);

// Prints absolute path to current working directory
// The path is copied inside buf, the size of which must be
// specified with the parameter "size"
	char *romfs_getcwd(char *buf, Uint32 size);

// Opens a directory stream associated with "path"
// and returns a pointer to the stream. Pointer is positioned
// at the first entry in the directory.
// On error, NULL is returned.
	ROMDIR *romfs_opendir(const char *path);

// Closes a dir stream pointer
	int romfs_closedir(ROMDIR *dirp);

// Resets the position of directory stream to first entry
	void romfs_rewinddir(ROMDIR *dirp);

// Reads an entry from dirp stream.
// Returns NULL in case of error, or when stream ended
	romfs_dirent *romfs_readdir(ROMDIR *dirp);

// same as access(...)
	Sint32 romfs_access(const char *path, Sint32 mode);

	/*** DUMMY ***/
// These functions obviously do nothing inside romfs...
	Uint32 romfs_write(const void *ptr, Uint32 size, Uint32 nmemb, ROMFILE *stream);
	Uint32 romfs_flush(ROMFILE *stream);

#ifdef __cplusplus
}
#endif

#endif

