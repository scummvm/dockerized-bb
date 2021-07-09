#ifndef _PI_h
#define _PI_h

#include "datatypes.h"

#define PI_BASE_REG		0x04600000

/* PI DRAM address (R/W): starting RDRAM address */
#define PI_DRAM_ADDR_REG	(PI_BASE_REG+0x00)	/* DRAM address */

/* PI pbus (cartridge) address (R/W): starting AD16 address */
#define PI_CART_ADDR_REG	(PI_BASE_REG+0x04)

/* PI read length (R/W): read data length */
#define PI_RD_LEN_REG		(PI_BASE_REG+0x08)

/* PI write length (R/W): write data length */
#define PI_WR_LEN_REG		(PI_BASE_REG+0x0C)

/*
 * PI status (R): [0] DMA busy, [1] IO busy, [2], error
 *           (W): [0] reset controller (and abort current op), [1] clear intr
 */
#define PI_STATUS_REG		(PI_BASE_REG+0x10)

/* PI dom1 latency (R/W): [7:0] domain 1 device latency */
#define PI_BSD_DOM1_LAT_REG	(PI_BASE_REG+0x14)

/* PI dom1 pulse width (R/W): [7:0] domain 1 device R/W strobe pulse width */
#define PI_BSD_DOM1_PWD_REG	(PI_BASE_REG+0x18)

/* PI dom1 page size (R/W): [3:0] domain 1 device page size */
#define PI_BSD_DOM1_PGS_REG	(PI_BASE_REG+0x1C)    /*   page size */

/* PI dom1 release (R/W): [1:0] domain 1 device R/W release duration */
#define PI_BSD_DOM1_RLS_REG	(PI_BASE_REG+0x20)

/* PI dom2 latency (R/W): [7:0] domain 2 device latency */
#define PI_BSD_DOM2_LAT_REG	(PI_BASE_REG+0x24)    /* Domain 2 latency */

/* PI dom2 pulse width (R/W): [7:0] domain 2 device R/W strobe pulse width */
#define PI_BSD_DOM2_PWD_REG	(PI_BASE_REG+0x28)    /*   pulse width */

/* PI dom2 page size (R/W): [3:0] domain 2 device page size */
#define PI_BSD_DOM2_PGS_REG	(PI_BASE_REG+0x2C)    /*   page size */

/* PI dom2 release (R/W): [1:0] domain 2 device R/W release duration */
#define PI_BSD_DOM2_RLS_REG	(PI_BASE_REG+0x30)    /*   release duration */

#define	PI_DOMAIN1_REG		PI_BSD_DOM1_LAT_REG
#define	PI_DOMAIN2_REG		PI_BSD_DOM2_LAT_REG

/*
 * PI status register has 3 bits active when read from (PI_STATUS_REG - read)
 *	Bit 0: DMA busy - set when DMA is in progress
 *	Bit 1: IO busy  - set when IO is in progress
 *	Bit 2: Error    - set when CPU issues IO request while DMA is busy
 */
#define	PI_STATUS_ERROR		0x04
#define	PI_STATUS_IO_BUSY	0x02
#define	PI_STATUS_DMA_BUSY	0x01

void PI_Init(void);
void PI_Init_SRAM(void);
void PI_DMAWait(void);
void PI_DMAFromCart(void* dest, void* src, Uint32 size);
void PI_DMAToCart(void* dest, void* src, Uint32 size);
void PI_DMAFromSRAM(void *dest, Uint32 offset, Uint32 size);
void PI_DMAToSRAM(void* src, Uint32 offset, Uint32 size);
void PI_SafeDMAFromCart(void *dest, void *src, Uint32 size);

#endif
