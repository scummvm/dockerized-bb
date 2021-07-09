/*
   Routines for interfacing the PIF via the SI, used primarily for controller
   access

   Thanks to LaC for controller information
*/

#include "N64sys.h"
#include "SI.h"
#include "datatypes.h"
#include <string.h>

volatile struct SI_regs_s * const SI_regs = (struct SI_regs_s *)0xA4800000;
static void * const PIF_RAM = (void *)0x1FC007C0;

/*
   anatomy of SI_read_con_keys_block
   0xff010401ffffffff
     \|\|\|\|\______|
      | | | |       |__ unused space, button data will be written here
      | | | |__ command 1: read controller button data
      | | |____ rx, receive 4 bytes (the button data)
      | |______ tx, transmit 1 byte (the command byte
      |________ tx, transmit 0xff bytes (thus ignored, just for padding)

   same for each of four channels (which correspond to the four controllers)

   0xfe00000000000000
     \|__ tx=0xfe, end of commands

   0,0 empty space

   1: bit 0 of byte 63, when set, makes the PIF run the task. It is cleared
      when finished.

*/

// Reads key/analog values
static Uint64 SI_read_con_keys_block[8] = {
	0xff010401ffffffff,
	0xff010401ffffffff,
	0xff010401ffffffff,
	0xff010401ffffffff,
	0xfe00000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000001
};

// Read controller status
static Uint64 SI_read_con_status_block[8] = {
	0xff010300ffffffff,
	0xff010300ffffffff,
	0xff010300ffffffff,
	0xff010300ffffffff,
	0xfe00000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000001
};

// Reset/Calibrate controllers
static Uint64 SI_reset_con_block[8] = {
	0xff0103ffffffffff,
	0xff0103ffffffffff,
	0xff0103ffffffffff,
	0xff0103ffffffffff,
	0xfe00000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000001
};

// Writes a mempak block
static Uint64 SI_read_pak_write_block[8] = {
	0xffffff2301030000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0xfe00000000000001
};

// Reads a mempak block
static Uint64 SI_read_pak_read_block[8] = {
	0xffffff0321020000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0xfe00000000000001
};

void SI_DMA_busy(void) {
	// clear interrupt
	while (SI_regs->status & (SI_status_DMA_busy | SI_status_IO_busy)) { }
}

void controller_exec_PIF(Uint64 const inblock[8], Uint64 outblock[8]) {
	volatile Uint64 inblock_temp[8];
	volatile Uint64 outblock_temp[8];

	data_cache_writeback_invalidate(inblock_temp, 64);
	memcpy(UncachedAddr(inblock_temp), inblock, 64);

	SI_DMA_busy();

	SI_regs->DRAM_addr = inblock_temp; // only cares about 23:0
	SI_regs->PIF_addr_write = PIF_RAM; // is it really ever anything else?

	SI_DMA_busy();

	data_cache_writeback_invalidate(outblock_temp, 64);

	SI_regs->DRAM_addr = outblock_temp;
	SI_regs->PIF_addr_read = PIF_RAM;

	SI_DMA_busy();

	memcpy(outblock, UncachedAddr(outblock_temp), 64);
}

void controller_Read_Buttons(controller_data_buttons * output) {
	controller_exec_PIF(SI_read_con_keys_block, (Uint64*)output);
}

void controller_Read_Status(controller_data_status * output) {
	controller_exec_PIF(SI_read_con_status_block, (Uint64 *)output);
}

// Generate a correct address CRC to put in the last 5 bits
// of the address when performing a controller pak read/write
Uint8 PackAddrCRC(Uint16 addr) {
	Uint8 t, t2;
	Uint32 i;

	t = 0;

	for (i = 0; i < 16; i++) {
		t2 = (t & 0x10) ? 0x15 : 0x00;
		t <<= 1;
		t = (addr & 0x8000) ? (t | 0x01) : t;
		addr <<= 1;
		t = t ^ t2;
	}

	return (t & 0x1F);
}

// Creates an address+crc to access the mempack
Uint16 createPakAddress(Uint16 addr) {
	addr &= 0xFFE0;
	return (addr | PackAddrCRC(addr));
}

// Read data from pak address to buffer
void controller_Read_Pak_Data(Uint8 channel, Uint16 address, Uint8 *buffer) {
	if (channel > 3) return;

	Uint16 fixaddr = createPakAddress(address); // Take care of crc...
	Uint64 destination_block[8];

	// Put the source address in the command block.
	SI_read_pak_read_block[0] = (SI_read_pak_read_block[0] & 0xffffffffffff0000) | fixaddr;

	// Put 0x00 in the first bytes. Used to select the channel (and the pak number) to access
	SI_read_pak_read_block[0] = (SI_read_pak_read_block[0] & (0xffffffffffffffff >> (8 * channel)));

	controller_exec_PIF(SI_read_pak_read_block, destination_block); // Read from pak

	*(Uint64*)(buffer +  0) = destination_block[1];
	*(Uint64*)(buffer +  8) = destination_block[2];
	*(Uint64*)(buffer + 16) = destination_block[3];
	*(Uint64*)(buffer + 24) = destination_block[4];

	return;
}

// Write data from buffer to pak address
void controller_Write_Pak_Data(Uint8 channel, Uint16 address, Uint8 *buffer) {
	if (channel > 3) return;

	Uint16 fixaddr = createPakAddress(address); // Take care of crc...
	Uint64 destination_block[8];

	SI_read_pak_write_block[1] = *(Uint64*)(buffer +  0);
	SI_read_pak_write_block[2] = *(Uint64*)(buffer +  8);
	SI_read_pak_write_block[3] = *(Uint64*)(buffer + 16);
	SI_read_pak_write_block[4] = *(Uint64*)(buffer + 24);

	// Put the source address in the command block.
	SI_read_pak_write_block[0] = (SI_read_pak_write_block[0] & 0xffffffffffff0000) | fixaddr;

	SI_read_pak_write_block[0] = (SI_read_pak_write_block[0] & (0xffffffffffffffff >> (8 * channel)));

	controller_exec_PIF(SI_read_pak_write_block, destination_block); // Write to mempak

	return;
}

void readControllerMemPak(Uint8 channel, Uint8 *buffer) {
	// Read all the 32bytes memory
	for (Uint16 bank = 0; bank < 1024; bank++) {
		controller_Read_Pak_Data(channel, 0x20 * bank, (buffer + (0x20 * bank)));
	}
}

void writeControllerMemPak(Uint8 channel, Uint16 address, Uint8 *buffer) {
	address &= 0xFFE0; // cut potentially dangerous last 5 bits
	Uint16 startBank = address / 0x20;
	Uint16 bufferBank = 0;

	// Write the data...
	for (Uint16 bank = startBank; bank < 1024; bank++, bufferBank++) {
		controller_Write_Pak_Data(channel, 0x20 * bank, (buffer + (0x20 * bufferBank)));
	}
}

void rumblePakEnable(Uint8 enable, Uint8 channel) {
	if (channel > 3) return;

	Uint8 rumble_code[0x20];

	// Make sure the rumble pak gets initialized
	memset(rumble_code, 0x80, 0x20);
	controller_Write_Pak_Data(channel, 0x8000, rumble_code);

	if (enable) // Enable rumbling
		memset(rumble_code, 0x01, 0x20);
	else // Disable rumbling
		memset(rumble_code, 0, 0x20);

	// Write the code into rumble address space
	controller_Write_Pak_Data(channel, 0xC000, rumble_code);
}

// Identifies the controller pak:
// -1 -> not plugged in/error
//  0 -> unknown device
//  1 -> Memory Pak
//  2 -> Rumble Pak
Sint8 identifyPak(Uint8 channel) {
	Uint8 read_buffer[0x20];
	controller_data_status cd;

	if (channel > 3) return -1;

	// This will then be re-read to check if a rumble pak is present
	memset(read_buffer, 0x80, 0x20);
	controller_Write_Pak_Data(channel, 0x8000, read_buffer);

	// Read controller status
	controller_Read_Status(&cd);

	// No pak (or controller) plugged in.
	if (cd.c[channel].expPak != 1) return -1;

	controller_Read_Pak_Data(channel, 0x8000, read_buffer);

	Uint8 isMemPak = 1;
	Uint8 isRumPak = 1;

	for (Uint16 i = 0; i < 0x20; i++) {
		if (read_buffer[i] != 0x00) isMemPak = 0;
		if (read_buffer[i] != 0x80) isRumPak = 0;
	}

	if (isMemPak) return 1;
	else if (isRumPak) return 2;
	else return 0;
}


