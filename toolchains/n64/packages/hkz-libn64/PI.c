#include <stdlib.h>
#include <malloc.h>
#include <string.h>

#include "PI.h"
#include "N64sys.h"

void PI_Init(void) {
	PI_DMAWait();
	IO_WRITE(PI_STATUS_REG, 0x03);
}

// Inits PI for sram transfer
void PI_Init_SRAM(void) {
	IO_WRITE(PI_BSD_DOM2_LAT_REG, 0x05);
	IO_WRITE(PI_BSD_DOM2_PWD_REG, 0x0C);
	IO_WRITE(PI_BSD_DOM2_PGS_REG, 0x0D);
	IO_WRITE(PI_BSD_DOM2_RLS_REG, 0x02);
}

void PI_DMAWait(void) {
	while (IO_READ(PI_STATUS_REG) & (PI_STATUS_IO_BUSY | PI_STATUS_DMA_BUSY));
}

void PI_DMAFromSRAM(void *dest, Uint32 offset, Uint32 size) {
	PI_DMAWait();

	IO_WRITE(PI_STATUS_REG, 0x03);
	IO_WRITE(PI_DRAM_ADDR_REG, K1_TO_PHYS(dest));
	IO_WRITE(PI_CART_ADDR_REG, (0xA8000000 + offset));
	data_cache_invalidate_all();
	IO_WRITE(PI_WR_LEN_REG, (size - 1));
}

void PI_DMAToSRAM(void* src, Uint32 offset, Uint32 size) {
	PI_DMAWait();

	IO_WRITE(PI_STATUS_REG, 0x02);
	IO_WRITE(PI_DRAM_ADDR_REG, K1_TO_PHYS(src));
	IO_WRITE(PI_CART_ADDR_REG, (0xA8000000 + offset));
	data_cache_invalidate_all();
	IO_WRITE(PI_RD_LEN_REG, (size - 1));
}

void PI_DMAFromCart(void* dest, void* src, Uint32 size) {
	PI_DMAWait();

	IO_WRITE(PI_STATUS_REG, 0x03);
	IO_WRITE(PI_DRAM_ADDR_REG, K1_TO_PHYS(dest));
	IO_WRITE(PI_CART_ADDR_REG, K0_TO_PHYS(src));
	data_cache_invalidate_all();
	IO_WRITE(PI_WR_LEN_REG, (size - 1));
}

void PI_DMAToCart(void* dest, void* src, Uint32 size) {
	PI_DMAWait();

	IO_WRITE(PI_STATUS_REG, 0x02);
	IO_WRITE(PI_DRAM_ADDR_REG, K1_TO_PHYS(src));
	IO_WRITE(PI_CART_ADDR_REG, K0_TO_PHYS(dest));
	data_cache_invalidate_all();
	IO_WRITE(PI_RD_LEN_REG, (size - 1));
}


// Wrapper to support unaligned access to memory
void PI_SafeDMAFromCart(void *dest, void *src, Uint32 size) {
	if (!dest || !src || !size) return;

	Uint32 unalignedSrc  = ((Uint32)src)  % 2;
	Uint32 unalignedDest = ((Uint32)dest) % 8;

	//FIXME: Do i really need to check if size is 16bit aligned?
	if (!unalignedDest && !unalignedSrc && !(size % 2)) {
		PI_DMAFromCart(dest, src, size);
		PI_DMAWait();

		return;
	}

	void* newSrc = (void*)(((Uint32)src) - unalignedSrc);
	Uint32 newSize = (size + unalignedSrc) + ((size + unalignedSrc) % 2);

	Uint8 *buffer = memalign(8, newSize);
	PI_DMAFromCart(buffer, newSrc, newSize);
	PI_DMAWait();

	memcpy(dest, (buffer + unalignedSrc), size);

	free(buffer);
}

