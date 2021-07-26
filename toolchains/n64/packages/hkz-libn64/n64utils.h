#ifndef __N64_UTILS__
#define __N64_UTILS__

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>

#include "datatypes.h"
#include "VI.h"
#include "N64sys.h"

	typedef struct {
		volatile int access;
	} N64Mutex;

// Conversion from a 32 bit BGRX colour to 16 bit RGB.
	Uint16 colourBGRX8888toRGB555(Uint32 colour);
	Uint16 colourBGR888toRGB555(Uint8 r, Uint8 g, Uint8 b);

	void drawTextLayer(struct VI_config *);
	void textLayerBreakPoint(char *line);
	void addLineTextLayer(char *line);
	void initTextLayer(void);
	void fprintf_n64(void *stream, const char *format, ...);

	/*** Error ***/
	int print_error(const char *, ...);

	/*** MUTEX ***/
	N64Mutex *createN64Mutex(void);
	void destroyN64Mutex(N64Mutex *mtx);
	void lockN64Mutex(N64Mutex *mtx);
	void unlockN64Mutex(N64Mutex *mtx);

	/*** MEMORY ***/
	void *safe_memalign(size_t boundary, size_t size);
	void *safe_calloc(size_t nmemb, size_t size);
	void *safe_malloc(size_t size);
	void safe_free(void *ptr);
	void *safe_memset(void *s, int c, size_t n);
	void *safe_memcpy(void *dest, const void *src, size_t n);

	/*** AUDIO ***/
// Init Audio Interface: sets clockrate (see AI.h), frequency of the samples that will be played,
// bits per sample, and the desired (as of now, works ok with 8kb onwards)
	void initAudioInterface(Uint32 clockrate, Uint32 frequency, Uint8 bitsPerSample, Uint32 bufferSize);

// The buffer size gets aligned to 8bytes. This returns the buffer size that is used by audio functions
	Uint32 getAIBufferSize(void);

// Returns a pointer to buffer where user writes
	Uint8*  getAIBuffer();

	void putAIBuffer(void);

	/*** VIDEO ***/
// Available video modes
	enum N64VideoMode {
		NTSC_320X240_16BIT,
		NTSC_340X240_16BIT,
		NTSC_640X480_16BIT,
		PAL_320X240_16BIT,
		PAL_340X240_16BIT,
		PAL_640X480_16BIT,
		MPAL_320X240_16BIT,
		MPAL_340X240_16BIT,
		MPAL_640X480_16BIT
	};

// Taken from alt-libn64 demo
	typedef struct display_context {
		struct VI_config conf;
		Sint32 idx;
	} _display_context;

// Init the display.
	void initDisplay(Uint32 vidmode);

// Returns a display to draw into. NULL if none is available
	struct display_context * lockDisplay();

// Show the display and the text layer
	void showDisplayAndText(struct display_context *);

// Shows the display
	void showDisplay(struct display_context *);

// Switch display in double buffered mode
	void switchDisplayBuffer(void);

// Clears (black) all personal video buffers
	void clearAllVideoBuffers(void);

	/*** MISC ***/
// Generates an hash from a string
	Uint32 hashString(const char *string);

#ifdef __cplusplus
}
#endif

#endif

