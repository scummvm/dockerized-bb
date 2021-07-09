#include "n64utils.h"
#include "datatypes.h"
#include "MI.h"

#include <malloc.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

Uint16 colourBGRX8888toRGB555(Uint32 colour) {
	Uint8 r = (colour & 0x0000FF00) >> 8;
	Uint8 g = (colour & 0x00FF0000) >> 16;
	Uint8 b = (colour & 0xFF000000) >> 24;

	return ((r >> 3) << 1) | ((g >> 3) << 6) | ((b >> 3) << 11);
}

Uint16 colourBGR888toRGB555(Uint8 r, Uint8 g, Uint8 b) {
	return ((r >> 3) << 1) | ((g >> 3) << 6) | ((b >> 3) << 11);
}

static char text[20][200];

void drawTextLayer(struct VI_config *screen) {
	Uint8 line;

	for (line = 0; line < 20; line++) {
		VI_DrawText(screen, 15, 15 + line * 10, "                              ");
		VI_DrawText(screen, 15, 15 + line * 10, text[line]);
	}
}

void initTextLayer(void) {
	memset(text, 0, 20 * 200);
}

void addLineTextLayer(char *line) {
	static Uint8 currentLine = 0;

	snprintf(text[currentLine], 199, "%s", line);

	currentLine = (currentLine + 1) % 20;
	text[currentLine][0] = '\0';
}

void fprintf_n64(void *stream, const char *format, ...) {
	char outstring[50];

	memset(outstring, 0, 50);

	va_list args;
	va_start(args, format);
	vsnprintf(outstring, 39, format, args);
	va_end(args);

	addLineTextLayer(outstring);
}

void textLayerBreakPoint(char *line) {
	struct display_context * dc;

	addLineTextLayer(line);

	while (1) {
		while (!(dc = lockDisplay())) ;

		drawTextLayer(&dc->conf);

		showDisplay(dc);
		dc = 0;
	}
}

/*** ERROR ***/
void fatal_error_handler(const char *);

int print_error(const char *format, ...) {
	char outstring[150];

	memset(outstring, 0, 150);
	outstring[149] = '\0';

	va_list args;
	va_start(args, format);
	vsnprintf(outstring, 149, format, args);
	va_end(args);

	fatal_error_handler((const char*)outstring);

	return 1;
}

/*** MUTEX ***/

static volatile int _lockedMutex = 0;

N64Mutex *createN64Mutex(void) {
	N64Mutex *mtx = (N64Mutex*)malloc(sizeof(N64Mutex));
	mtx->access = 0;

	return mtx;
}

void destroyN64Mutex(N64Mutex *mtx) {

	if (mtx->access) _lockedMutex -= mtx->access;

	free(mtx);

	if (!_lockedMutex)
		disable_interrupts();
}

void lockN64Mutex(N64Mutex *mtx) {
	if (!mtx) return;

	disable_interrupts();

	while (mtx->access);
	mtx->access++;
	_lockedMutex++;
}

void unlockN64Mutex(N64Mutex *mtx) {
	if (!mtx) return;

	mtx->access--;
	_lockedMutex--;

	if (!_lockedMutex)
		enable_interrupts();
}

/*** MEMORY ***/

void *safe_memcpy(void *dest, const void *src, size_t n) {
	if (!dest || !src || !n) return dest;

	Uint32 status;
	fetch_status_register(status);
	disable_interrupts();

	dest = memcpy(dest, src, n);

	set_status_register(status);

	return dest;
}


void *safe_memset(void *s, int c, size_t n) {
	if (!s) return NULL;

	Uint32 status;
	fetch_status_register(status);
	disable_interrupts();

	s = memset(s, c, n);

	set_status_register(status);

	return s;
}

void *safe_memalign(size_t boundary, size_t size)  {
	if (!boundary || !size) return NULL;
	void *buf;

	Uint32 status;
	fetch_status_register(status);
	disable_interrupts();

	buf = memalign(boundary, size);

	set_status_register(status);

	return buf;
}

void *safe_calloc(size_t nmemb, size_t size)  {
	void *buf = NULL;

	Uint32 status;
	fetch_status_register(status);
	disable_interrupts();

	buf = calloc(nmemb, size);

	set_status_register(status);

	return buf;
}

void *safe_malloc(size_t size) {
	void *buf = NULL;

	Uint32 status;
	fetch_status_register(status);
	disable_interrupts();

	buf = malloc(size);

	set_status_register(status);

	return buf;
}

void safe_free(void *ptr) {
	if (!ptr) return;

	Uint32 status;
	fetch_status_register(status);
	disable_interrupts();

	free(ptr);

	set_status_register(status);

}

/*** MISC ***/

Uint32 hashString(const char *string) {
	char c, *f ;
	Uint32 n ;

	if (!string)
		return 0 ;

	n = 0 ;
	f = (char *)string ;

	while ((c = *f) != 0) {
		n = (n << 7) + (n << 1) + n + c ;
		f++ ;
	}

	return n ;
}


