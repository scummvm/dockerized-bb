/*
 * VI (Video Interface)
 */

#include "VI.h"

extern unsigned char VI_fontdata[2048];

volatile struct VI_regs_s * const VI_regs = (struct VI_regs_s *)0xA4400000;

void VI_WriteRegs(struct VI_config * conf) {
	VI_regs->control = conf->mode[0];
	VI_regs->framebuffer = conf->framebuffer;
	VI_regs->width = conf->mode[1];
	VI_regs->v_int = conf->mode[2];	// used for VI interrupt
	VI_regs->cur_line = conf->mode[3];  // tells current line, write to clear interrupt
	VI_regs->timing = conf->mode[4]; // fairly standard?
	VI_regs->v_sync = conf->mode[5];
	VI_regs->h_sync = conf->mode[6];
	VI_regs->h_sync2 = conf->mode[7];
	VI_regs->h_limits = conf->mode[8];
	VI_regs->v_limits = conf->mode[9];
	VI_regs->color_burst = conf->mode[10]; // likewise?
	VI_regs->h_scale = conf->mode[11];
	VI_regs->v_scale = conf->mode[12];
}

void VI_RetraceStartWait(void) {
	// if already in retrace will wait for the next one
	while (VI_regs->cur_line != 0x200) {}
}

void VI_RetraceEndWait(void); // TODO

void VI_FillScreen(struct VI_config * conf, unsigned short color) {
	for (int c = 0; c < conf->xres*conf->yres; c++) conf->framebuffer[c] = color;
}

void inline VI_DrawPixel(struct VI_config * conf, unsigned int x, unsigned int y,
                         unsigned short color) {
	conf->framebuffer[y*conf->xres+x] = color;
}

void VI_DrawText(struct VI_config * conf, int xstart, int y, unsigned char * message) {
	int x = xstart;

	while (*message) {
		if (*message == '\n') {
			x = xstart;
			y += 8;
			message++;
			continue;
		}
		for (int row = 0; row < 8; row++) {
			Uint8 c = VI_fontdata[(int)(*message)*8+row];
			for (int col = 0; col < 8; col++) {
				Uint16 colour = ((c & 0x80) ? 0xfffe : 0);
				if (colour)
					VI_DrawPixel(conf, x + col, y + row, (c&0x80) ? 0xfffe : 0);
				c <<= 1;
			}
		}
		x += 8;
		message++;
	}
}
