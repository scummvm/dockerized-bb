/*
   N64 init code for GNU as
*/

#include "regs.S"

.section .init
	.globl _start
_start:
	li v0, 8
    sw v0,(0xBFC007FC)	/* magic N64 hardware init */
	lw t0, 0x80000318 /* Load memory size in t0 */
	li t1, 0x7FFFFFF0
	addu sp,t0,t1  /* Init program stack */
data_pointer_init:
	la gp, _gp		/* init data pointer */

/* a bit from libgloss so we start at a known state */
    li v0,SR_CU1|SR_PE|SR_FR|SR_KX|SR_SX|SR_UX
	mtc0 v0,C0_SR
	mtc0 $0,C0_CAUSE

/* Copy program code */
	la a0,__after_init
	la a1,end
	subu a2,a0,0x80000400
	addu a2,a2,0xB0001000 /* a2 -> program beginning in cart */
copy_program_code:
	lw t0, (a2)
	sw t0, (a0)
	addu a2, a2, 4 /* next word */
	addu a0, a0, 4
	bne a0,a1,copy_program_code
	nop

/* Clean BSS */
	la a0, __bss_start
	la a1, __bss_end
clean_bss:
	sw zero, (a0)
	addu a0, a0, 4
	bne a0, a1, clean_bss
	nop

/* Clean SBSS */
	la a0, __sbss_start
	la a1, __sbss_end
clean_sbss:
	sw zero, (a0)
	addu a0, a0, 4
	bne a0, a1, clean_sbss
	nop

/* commit data */
	la a0,__data_start
	la a1,__data_end
	sub a1,a0
	jal data_cache_writeback_invalidate
	nop

/* commit text */
	la a0,__text_start
	la a1,__text_end
	sub a1,a0
	jal inst_cache_writeback_invalidate
	nop

/* initialize some vars */
	la a0, regStack
	sw a0, regStackPos

/* load interrupt vector */
	la t0,intvector
	la t1,0xA0000000
	la t2,4
loadintvectorloop:
	lw t3,(t0)
    	sw t3,0(t1)
    	sw t3,0x80(t1)
    	sw t3,0x100(t1)
    	sw t3,0x180(t1)
	//sync
	cache HIT_INVALIDATE_I,0(t1)
    	cache HIT_INVALIDATE_I,0x80(t1)
    	cache HIT_INVALIDATE_I,0x100(t1)
    	cache HIT_INVALIDATE_I,0x180(t1)
    	addi t0,4
	addi t1,4
	addiu t2,-1
	bnez t2,loadintvectorloop
	nop

        jal __init /* Jump to pre-main function */
	nop
deadloop:
	j deadloop
	nop

intvector:
	la k1,inthandler
	jr k1
	nop

