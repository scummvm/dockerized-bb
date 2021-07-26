#ifndef __N64SYS_H__
#define __N64SYS_H__

/*
   General R4300 stuff
*/

#include "datatypes.h"

#define UncachedAddr(_addr) ((void *)(((Uint32)(_addr))|0x20000000))
#define UncachedShortAddr(_addr) ((Sint16 *)(((Uint32)(_addr))|0x20000000))
#define UncachedUShortAddr(_addr) ((Uint16*)(((Uint32)(_addr))|0x20000000))
#define UncachedLongAddr(_addr) ((Sint32 *)(((Uint32)(_addr))|0x20000000))
#define UncachedULongAddr(_addr) ((Uint32 *)(((Uint32)(_addr))|0x20000000))
#define CachedAddr(_addr) ((void *)(((Uint32)(_addr))&~0x20000000))

// IO Functions by Hkz, taken from libn64
#define	PHYS_TO_K0(x)	((Uint32)(x)|0x80000000)	/* physical to kseg0 */
#define	K0_TO_PHYS(x)	((Uint32)(x)&0x1FFFFFFF)	/* kseg0 to physical */
#define	PHYS_TO_K1(x)	((Uint32)(x)|0xA0000000)	/* physical to kseg1 */
#define	K1_TO_PHYS(x)	((Uint32)(x)&0x1FFFFFFF)	/* kseg1 to physical */

#define	IO_READ(addr)		(*(volatile Uint32*)PHYS_TO_K1(addr))
#define	IO_WRITE(addr,data)	(*(volatile Uint32*)PHYS_TO_K1(addr)=(Uint32)(data))
// End ...

// Get ticks from the free running timer of the RISC processor
#define getSysTicker(x) asm volatile("mfc0 %0, $9\n\t nop \n\t" : "=r" (x) : );

#define	N64_CLOCK_RATE		62500000LL
#define	N64_CPU_COUNTER	(N64_CLOCK_RATE*3/4)
#define N64_CYCLES_TO_USEC(c)	(((Uint64)(c)*(1000000LL/15625LL))/(N64_CPU_COUNTER/15625LL))
#define N64_CYCLES_TO_NSEC(c)	(((Uint64)(c)*(1000000000LL/15625000LL))/(N64_CPU_COUNTER/15625000LL))
#define N64_USEC_TO_CYCLES(n)	(((Uint64)(n)*(N64_CPU_COUNTER/15625LL))/(1000000LL/15625LL))
#define N64_NSEC_TO_CYCLES(n)	(((Uint64)(n)*(N64_CPU_COUNTER/15625000LL))/(1000000000LL/15625000LL))

#define fetch_status_register(x) asm volatile("mfc0 %0, $12\n\t nop\n\t" : "=r" (x):);
#define set_status_register(x)   asm volatile("mtc0 %0, $12\n\t nop\n\t" : : "r"  (x));

#define disable_interrupts() asm volatile("mfc0 $8, $12\n\t nop\n\t li $9, ~1\n\t and $8, $9\n\t mtc0 $8, $12\n\t nop" :::"$8","$9")
#define enable_interrupts()	 asm volatile("mfc0 $8, $12\n\t nop\n\t ori $8, 1\n\t mtc0 $8, $12\n\t nop" :::"$8")

void data_cache_invalidate(volatile void *, Uint32);
void data_cache_writeback(volatile void *, Uint32);
void data_cache_writeback_invalidate(volatile void *, Uint32);
void inst_cache_invalidate(volatile void *, Uint32);
void inst_cache_writeback(volatile void *, Uint32);
void inst_cache_writeback_invalidate(volatile void *, Uint32);
void data_cache_invalidate_all(void);

// Returns a counter in milliseconds
Uint32 getMilliTick(void);

// Delay millisec milliseconds...
void delay(Uint32 millisec);

#endif // __N64SYS_H__
