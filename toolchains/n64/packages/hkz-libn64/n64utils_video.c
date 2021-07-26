#include "n64utils.h"
#include "datatypes.h"
#include "VI.h"
#include "MI.h"
#include "N64sys.h"

#include <malloc.h>
#include <string.h>

// This file includes available video modes
#include "n64utils_vidmodes.c"

#define BUFFER_COUNT 2

// frame buffers
static Uint8 *fb[BUFFER_COUNT];

// display contexts
static struct display_context dc[BUFFER_COUNT];

// Indexes to manage buffer switching
static volatile Sint8 nowshowing; // currently displayed buffer
static volatile Sint8 shownext; // complete drawn buffer to display next
static volatile Sint8 nowdrawing; // buffer currently being drawn on

static Uint16 x_res, y_res;
static Uint8 pixelSize;

void initDisplay(Uint32 vidmode) {
	Uint32 *mode = NULL;

	switch (vidmode) {
	case PAL_320X240_16BIT:
		mode = VI_PAL_LORES_OVER;
		break;

	case PAL_340X240_16BIT:
		mode = VI_PAL_LORES_NOVER;
		break;

	case PAL_640X480_16BIT:
		mode = VI_PAL_HIRES_NOVER;
		break;

	case MPAL_320X240_16BIT:
		mode = VI_MPAL_LORES_OVER;
		break;

	case MPAL_340X240_16BIT:
		mode = VI_MPAL_LORES_NOVER;
		break;

	case MPAL_640X480_16BIT:
		mode = VI_MPAL_HIRES_NOVER;
		break;

	case NTSC_320X240_16BIT:
		mode = VI_NTSC_LORES_OVER;
		break;

	case NTSC_340X240_16BIT:
		mode = VI_NTSC_LORES_NOVER;
		break;

	case NTSC_640X480_16BIT:
		mode = VI_NTSC_HIRES_NOVER;
		break;

	default:
		mode = VI_NTSC_LORES_OVER;
		break;
	}

	Uint32 control = mode[0];

	Uint8 bitdepth = ((control & 0x03) == 2) ? 16 : (((control & 0x03) == 3) ? 32 : 0);
	pixelSize = (bitdepth == 16) ? 2 : 4;

	x_res = mode[1];

	switch (x_res) {
	case 320:
		y_res = 240;
		break;
	case 340:
		y_res = 240;
		break;
	case 640:
		y_res = 480;
		break;
	default: // Fallback...
		y_res = 240;
		break;
	}

	for (int buf = 0; buf < BUFFER_COUNT; buf++) {
		if (fb[buf]) free(fb[buf]);

		fb[buf] = memalign(8, x_res * y_res * (bitdepth / 8));
		memset(fb[buf], 0, x_res * y_res * (bitdepth / 8));
	}

	// Set up the display contexts
	for (int c = 0; c < BUFFER_COUNT; c++) {
		dc[c].conf.xres = x_res;
		dc[c].conf.yres = y_res;
		dc[c].conf.mode = mode;
		dc[c].conf.framebuffer = UncachedAddr(fb[c]);
		dc[c].idx = c;
	}

	VI_WriteRegs(&dc[0].conf);

	nowshowing = 0;
	nowdrawing = -1;
	shownext = -1;

	//registerVIhandler(showNextDisplay);
	set_VI_interrupt(1);
}

// Request a display context to write upon.
// Will return null pointer if nothing is available right away.
struct display_context * lockDisplay() {
	struct display_context * retval = 0;
	disable_interrupts();
	for (int c = 0;c < BUFFER_COUNT;c++) {
		if (c != nowshowing && c != nowdrawing && c != shownext) {
			nowdrawing = c;
			retval = &dc[c];
			break;
		}
	}
	enable_interrupts();
	return retval;
}

void showDisplayAndText(struct display_context * dc_to_show) {
	drawTextLayer(&dc_to_show->conf);
	showDisplay(dc_to_show);
}

// Say that you are done, display the image.
// This will replace an existing complete image to "shownext"
void showDisplay(struct display_context * dc_to_show) {
	disable_interrupts(); // can't have the exception handler blowing this...

	if (dc_to_show->idx == nowdrawing) nowdrawing = -1; // if not something is wrong
	shownext = dc_to_show->idx;

	enable_interrupts();
}

void switchDisplayBuffer(void) {
	if (shownext >= 0 && shownext != nowdrawing) {
		VI_WriteRegs(&dc[shownext].conf);
		nowshowing = shownext;
		shownext = -1;
	}
	// otherwise just leave the current one up
}

void clearAllVideoBuffers(void) {
	int curBuf;

	for (curBuf = 0; curBuf < BUFFER_COUNT; curBuf++)
		memset(fb[curBuf], 0, x_res * y_res * pixelSize);
}

