/*
 * Routines for using the AI to play sound
 */

#include "AI.h"
#include "N64sys.h"

volatile struct AI_regs_s * const AI_regs = (struct AI_regs_s *)0xA4500000;

Uint32 AI_busy() {
	return AI_regs->status & AI_status_busy;
}

Uint32 AI_full() {
	return AI_regs->status & AI_status_full;
}

void AI_set_frequency(Uint32 freq, Uint32 clock, Uint8 bitrate) {
	AI_regs->dacrate = (clock / freq) - 1;
	AI_regs->samplesize = bitrate - 1;
}

void AI_add_buffer(Sint16 * buf, Uint32 len) {
//   while (AI_full()) {}
	AI_regs->address = UncachedAddr(buf);
	AI_regs->length = (Uint32)(len & 0xFFFFFFF8);
	AI_regs->control = 1; /* start DMA */
}

void AI_start_dma(void) {
	AI_regs->control = 1; /* start DMA */

}
