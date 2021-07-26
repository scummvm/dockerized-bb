#ifndef _SI_h
#define _SI_h

#include "datatypes.h"

typedef struct SI_regs_s {
	volatile void * DRAM_addr;
	volatile void * PIF_addr_read; // for a read from PIF RAM
	unsigned long reserved1, reserved2;
	volatile void * PIF_addr_write; // for a write to PIF RAM
	unsigned long reserved3;
	unsigned long status;
} _SI_regs_s;

#define SI_status_DMA_busy	(1<<0)
#define SI_status_IO_busy	(1<<1)
#define SI_status_DMA_error	(1<<3)
#define SI_status_interrupt	(1<<12)

/* SI_condat
 * error   -> bit 15-16: error status
 *
 * On a standard N64 pad
 * buttons -> bit 16:  A 
 *            bit 15:  B
 *            bit 14:  Z
 *            bit 13:  START
 *            bit 12:  UP
 *            bit 11:  DOWN
 *            bit 10:  LEFT
 *            bit 9:   RIGHT
 *            bit 7-8: ?
 *            bit 6:   TRIGGER LEFT
 *            bit 5:   TRIGGER RIGHT
 *            bit 4:   C_UP
 *			  bit 3:   C_DOWN
 *            bit 2:   C_LEFT
 *            bit 1:   C_RIGHT
 *
 * throttle -> bit 9-16: ANALOG X AXIS
 *             bit 1-8:  ANALOG Y AXIS
 */

typedef struct {
	Uint32 error;
	Uint16 buttons; 
	Uint16 throttle;
} SI_condat;

/* Device types */
#define CTRL_PAD_STANDARD 0x0500 // Standard N64 pad type
#define CTRL_N64_MOUSE    0x0200 // Mouse bundled with Mario Paint

typedef struct {
	Uint32 error;

	Uint16 type;
	Uint8 expPak; // Is an expansion device plugged in?
	Uint8 unused;
} SI_constat;

typedef struct {
	SI_condat c[4];
	Uint32 unused[4*8]; // to map directly to PIF block
} controller_data_buttons;

typedef struct {
	SI_constat c[4];
	Uint32 unused[4*8]; // to map directly to PIF block
} controller_data_status;


void controller_Read_Buttons(controller_data_buttons *); // Read controller keys
void controller_Read_Status(controller_data_status *); // Read controller status

// Read & Write data to/from the controller pak
// NOTES: The address must be in 32byte boundary, and the buffer must be 0x20 (32) bytes in size.
void controller_Read_Pak_Data(Uint8 channel, Uint16 address, Uint8 *buffer);
void controller_Write_Pak_Data(Uint8 channel, Uint16 address, Uint8 *buffer);

// Read the full mempak memory and store it in the buffer.
// WARNING: The buffer must be at least 32 kilobytes in size!
void readControllerMemPak(Uint8 channel, Uint8 *buffer);

// Writes buffer content to controller mempak at address specified (it will be aligned at 32 bytes)
void writeControllerMemPak(Uint8 channel, Uint16 address, Uint8 *buffer);

// If rumble pak is inserted, it can disable or enable the rumbling feature
void rumblePakEnable(Uint8 enable, Uint8 channel);

void controller_exec_PIF(unsigned long long const [8], unsigned long long [8]);

// Identifies the controller pak:
// -1 -> not plugged in/error
//  0 -> unknown device
//  1 -> Memory Pak
//  2 -> Rumble Pak
Sint8 identifyPak(Uint8 channel);

#endif // _SH_h
