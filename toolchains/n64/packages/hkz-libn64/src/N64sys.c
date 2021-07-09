#include "N64sys.h"

#define cache_op(op) \
    addr=(void*)(((Uint32)addr)&(~3));\
    for (;length>0;length-=4,addr+=4) \
	asm ("\tcache %0,(%1)\n"::"i" (op), "r" (addr))

void data_cache_writeback(volatile void * addr, Uint32 length) {
	cache_op(0x19);
}
void data_cache_invalidate(volatile void * addr, Uint32 length) {
	cache_op(0x11);
}
void data_cache_writeback_invalidate(volatile void * addr, Uint32 length) {
	cache_op(0x15);
}
void inst_cache_writeback(volatile void * addr, Uint32 length) {
	cache_op(0x18);
}
void inst_cache_invalidate(volatile void * addr, Uint32 length) {
	cache_op(0x10);
}
void inst_cache_writeback_invalidate(volatile void * addr, Uint32 length) {
	cache_op(0x14);
}

void data_cache_invalidate_all(void) {
	asm(
	    "li $8,0x80000000\n"
	    "li $9,0x80000000\n"
	    "addu $9,$9,0x1FF0\n"
	    "cacheloop:\n"
	    "cache 1,0($8)\n"
	    "cache 1,16($8)\n"
	    "cache 1,32($8)\n"
	    "cache 1,48($8)\n"
	    "cache 1,64($8)\n"
	    "cache 1,80($8)\n"
	    "cache 1,96($8)\n"
	    "addu $8,$8,112\n"
	    "bne $8,$9,cacheloop\n"
	    "cache 1,0($8)\n"
    : // no outputs
    : // no inputs
    : "$8", "$9" // trashed registers
	);
}

