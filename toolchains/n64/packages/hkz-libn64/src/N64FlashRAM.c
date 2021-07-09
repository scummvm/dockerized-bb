#include "N64sys.h"
#include "PI.h"
#include "N64FlashRAM.h"
#include "n64utils.h"

#include <string.h>

#define fram_cmd(cmd)	IO_WRITE(FRAM_COMMAND_REG, cmd)
#define fram_get_status()	IO_READ(FRAM_STATUS_REG)
#define fram_set_addr(cmd, addr)	(cmd | (addr & 0xFFFF))

#define FRAM_EXECUTE_CMD		0xD2000000
#define FRAM_STATUS_MODE_CMD	0xE1000000
#define FRAM_ERASE_OFFSET_CMD	0x4B000000
#define FRAM_WRITE_OFFSET_CMD	0xA5000000
#define FRAM_ERASE_MODE_CMD		0x78000000
#define FRAM_WRITE_MODE_CMD		0xB4000000
#define FRAM_READ_MODE_CMD		0xF0000000

void FRAM_Init(void) {
	PI_Init_SRAM();

	fram_cmd(FRAM_EXECUTE_CMD);
	delay(10);

	fram_cmd(FRAM_EXECUTE_CMD);
	delay(10);

	fram_cmd(FRAM_STATUS_MODE_CMD);
	delay(10);

}

void FRAM_EraseBank(Uint32 bankNo) {

	bankNo = ((bankNo * 128) + 128) - 1;

	Uint8 erased = 2;
	while (erased) {
		fram_cmd(fram_set_addr(FRAM_ERASE_OFFSET_CMD, bankNo));
		delay(1);
		fram_cmd(FRAM_ERASE_MODE_CMD);
		delay(1);
		fram_cmd(FRAM_EXECUTE_CMD);
		delay(10);

		erased--;
	}
}

// Offset is in groups of 128 bytes.
void FRAM_SetWritingOffset(Uint32 offset) {
	fram_cmd(fram_set_addr(FRAM_WRITE_OFFSET_CMD, offset));
	delay(1);
}

// Writes 128 bytes block
void FRAM_WriteBlock(Uint8 *src, Uint32 blockNo) {
	Uint8 copied = 2;
	while (copied) {
		fram_cmd(FRAM_WRITE_MODE_CMD);
//		delay(1);

		PI_DMAToSRAM(src, 0, 128);
		PI_DMAWait();

		FRAM_SetWritingOffset(blockNo);

		fram_cmd(FRAM_EXECUTE_CMD);
//		delay(1);

		copied--;
	}
}

// Writes a 960 bytes slot
void FRAM_WriteSlot(Uint8 *src, Uint32 slotNo) {
	Uint32 startBlock = slotNo * 8;

	for (Uint8 block = 0; block < 8; block++) {
		FRAM_WriteBlock(src + (block * 128), startBlock + block);
	}
}

// Writes a 15360 bytes bank
void FRAM_WriteBank(Uint8 *src, Uint32 bankNo) {
	Uint32 startSlot = bankNo * 16;

	for (Uint8 slot = 0; slot < 16; slot++) {
		FRAM_WriteSlot(src + (slot * 960), startSlot + slot);
	}
}

void FRAM_ReadBlock(Uint8 *dst, Uint32 blockNo) {
	Uint32 blockOffset = blockNo * 128;

	FRAM_Read(dst, blockOffset, 128);
}

void FRAM_ReadSlot(Uint8 *dst, Uint32 slotNo) {
	Uint8 buffer[2 * 1024];
	Uint32 startBlock = slotNo * 8;

	for (Uint8 block = 0; block < 8; block++) {
		FRAM_ReadBlock(buffer + (block * 128), startBlock + block);
	}

	memcpy(dst, buffer, 960);
}

void FRAM_ReadBank(Uint8 *dst, Uint32 bankNo) {
	Uint8 buffer[16 * 1024];
	Uint32 startSlot = bankNo * 16;

	for (Uint8 slot = 0; slot < 16; slot++) {
		FRAM_ReadSlot(buffer + (slot * 960), startSlot + slot);
	}

	memcpy(dst, buffer, 960 * 16);
}

void FRAM_Read(Uint8 *dst, Uint32 offset, Uint32 size) {
	fram_cmd(FRAM_READ_MODE_CMD); // Enable read mode
//	delay(1);

	PI_DMAFromSRAM(dst, (offset / 2), size);
	PI_DMAWait();
}

void FRAM_Status(Uint64 *status) {
	fram_cmd(FRAM_STATUS_MODE_CMD); // Enable status mode
	delay(1);

	PI_DMAFromSRAM(status, 0, 8);
	PI_DMAWait();
}

Uint8 FRAM_Detect(void) {
	Uint64 status;

	FRAM_Status(&status);

	status >>= 48;

	if (status == 0x1111) return 1;
	else return 0;
}

