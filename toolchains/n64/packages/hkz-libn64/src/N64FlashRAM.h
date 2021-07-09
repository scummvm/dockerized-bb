#ifndef __N64_FLASHRAM__
#define __N64_FLASHRAM__

/* Units:
 * BLOCK = 128 bytes
 * SLOT = 8 * BLOCKS; 960 bytes. the last block holds only 64bytes, instead of 128.
 * BANK = 16 * SLOTS; 15360 bytes.
 *
 * There are 1024 BLOCKs
 * 128 SLOTs
 * 8 BANKs
 */

#define FRAM_STATUS_REG	0xA8000000
#define FRAM_COMMAND_REG 0xA8010000

void FRAM_Init(void);

// Erase bank
// BEWARE: Before a block can be written, it MUST be erased.
// Flashram bits can only be "turned off", once a bit is turned off, the only way
// to turn it back on, is erasing the whole bank in which it resides.
void FRAM_EraseBank(Uint32 bankNo);

// Write 128 bytes (64 if last slot of slot) into block.
void FRAM_WriteBlock(Uint8 *src, Uint32 blockNo);

// Write 960 bytes in the slot.
void FRAM_WriteSlot(Uint8 *src, Uint32 slotNo);

// Write 15360 bytes in bank.
void FRAM_WriteBank(Uint8 *src, Uint32 bankNo);

// Read 128 bytes from block (if block is last of slot, last 64b will contain garbage)
void FRAM_ReadBlock(Uint8 *dst, Uint32 blockNo);

// Read 960 bytes from the slot.
void FRAM_ReadSlot(Uint8 *dst, Uint32 slotNo);

// Read 15360 bytes in bank.
void FRAM_ReadBank(Uint8 *dst, Uint32 bankNo);

// Generic read in flashram. Offset must be even.
void FRAM_Read(Uint8 *dst, Uint32 offset, Uint32 size);

void FRAM_Status(Uint64 *status);

// 1 if FRAM is found, 0 if not
Uint8 FRAM_Detect(void);

#endif
