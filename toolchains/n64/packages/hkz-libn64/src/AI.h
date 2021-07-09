#ifndef _AI_H
#define _AI_H

#include "datatypes.h"

typedef struct AI_regs_s {
	Sint16 * address;
	Uint32 length;
	Uint32 control;
	Uint32 status;
	Uint32 dacrate;
	Uint32 samplesize;
} _AI_regs_s;

extern volatile struct AI_regs_s * const AI_regs;

#define VI_NTSC_CLOCK		48681812        /* Hz = 48.681812 MHz */
#define VI_PAL_CLOCK		49656530        /* Hz = 49.656530 MHz */
#define VI_MPAL_CLOCK		48628316        /* Hz = 48.628316 MHz */

#define AI_status_busy (1<<30)
#define AI_status_full (1<<31)

void AI_start_dma(void);
void AI_add_buffer(Sint16 * buf, Uint32 len);
void AI_set_frequency(Uint32 freq, Uint32 clock, Uint8 bitrate);
Uint32 AI_busy();
Uint32 AI_full();

#endif
