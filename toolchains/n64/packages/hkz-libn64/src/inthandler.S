/*
   Simple interrupt handler, hands off MIPS interrupts to higher level processes.
   Based on INITS.inc from Neon64.

   It is not reentrant, so interrupts are disabled for the duration.
   Safe for doing most things, including FPU operations, within handlers.

*/

#include "regs.S"

.globl regStack
.globl regStackPos

.globl inthandler

.set noreorder

inthandler:
	.set noat
wait:
	/* This might get interrupted, but
	 * the exception handler will restore k0 and k1 to
	 * sane values at the end
	 */
	lw k0, regStackPos
	addi k0, k0, 600
	la k1, regStackPos
	sw k0, (k1) // Increase and save regStackPos

	sd $1,-8(k0)

	/* Disable interrupts */
	mfc0 k1,C0_SR
	nop
	sw k1, -16(k0) /* SR */
	li $1, ~1
	and k1,$1
	mtc0 k1, C0_SR
	nop
	.set at

	/* save GPRs */
	sd $2,-32(k0)
	sd $3,-40(k0)
	sd $4,-48(k0)
	sd $5,-56(k0)
	sd $6,-64(k0)
	sd $7,-72(k0)
	sd $8,-80(k0)
	sd $9,-88(k0)
	sd $10,-96(k0)
	sd $11,-104(k0)
	sd $12,-112(k0)
	sd $13,-120(k0)
	sd $14,-128(k0)
	sd $15,-136(k0)
	sd $16,-144(k0)
	sd $17,-152(k0)
	sd $18,-160(k0)
	sd $19,-168(k0)
	sd $20,-176(k0)
	sd $21,-184(k0)
	sd $22,-192(k0)
	sd $23,-200(k0)
	sd $24,-208(k0)
	sd $25,-216(k0)
	sd $26,-224(k0) /* k0 */
	sd $27,-232(k0) /* k1 */
	sd $28,-240(k0)
	sd $29,-248(k0)
	sd $30,-256(k0)
	sd $31,-264(k0)
	
	mflo $30
	nop
	sd $30,-272(k0) /* LO */
	
	mfhi $30
	nop
	sd $30,-280(k0) /* HI */
	
	cfc1 $30,$f31
	nop
	sd $30,-288(k0) /* FC31 */
	
	mfc0 $30, $8
	nop
	sw $30, -552(k0) /* BadVaddr */

	mfc0 $30, $14
	nop
	sw $30, -560(k0) /* EPC */

	mfc0 $30, $13
	nop
	sw $30, -568(k0) /* Cause */

	sdc1 $f0,-296(k0)
	sdc1 $f1,-304(k0)
	sdc1 $f2,-312(k0)
	sdc1 $f3,-320(k0)
	sdc1 $f4,-328(k0)
	sdc1 $f5,-336(k0)
	sdc1 $f6,-344(k0)
	sdc1 $f7,-352(k0)
	sdc1 $f8,-360(k0)
	sdc1 $f9,-368(k0)
	sdc1 $f10,-376(k0)
	sdc1 $f11,-384(k0)
	sdc1 $f12,-392(k0)
	sdc1 $f13,-400(k0)
	sdc1 $f14,-408(k0)
	sdc1 $f15,-416(k0)
	sdc1 $f16,-424(k0)
	sdc1 $f17,-432(k0)
	sdc1 $f18,-440(k0)
	sdc1 $f19,-448(k0)
	sdc1 $f20,-456(k0)
	sdc1 $f21,-464(k0)
	sdc1 $f22,-472(k0)
	sdc1 $f23,-480(k0)
	sdc1 $f24,-488(k0)
	sdc1 $f25,-496(k0)
	sdc1 $f26,-504(k0)
	sdc1 $f27,-512(k0)
	sdc1 $f28,-520(k0)
	sdc1 $f29,-528(k0)
	sdc1 $f30,-536(k0)
	sdc1 $f31,-544(k0)

	li t1, 0x10 
	sub sp, sp, t1 /* Calculate stack pointer position */
	//lui t0,0xa000
	//or sp,t0
	//or gp,t0

	//j notcount
	//nop

	mfc0 k1,C0_CAUSE
	nop
	andi $30,k1,0xff
	beqz $30, justaninterrupt
	nop
	/* Printing crash screen */
	jal crash_handler
	nop
justaninterrupt:
	/* check for "pre-NMI" (reset) */
	andi $30,k1,0x1000
	beqz $30, notprenmi
	nop
	/* TODO: handle reset */
	j endint
	nop
notprenmi:

	/* check for count=compare */
	and $30,k1,0x8000
	beqz $30,notcount
	nop
	mtc0 $0,$11
	nop
	/* TODO: handle compare exception */

	j endint
	nop
notcount:

	/* pass anything else along to handler */
	jal MI_handler
	nop
	
endint:
	lw k0, regStackPos

	/* restore GPRs */
	ld $2,-32(k0)
	ld $3,-40(k0)
	ld $4,-48(k0)
	ld $5,-56(k0)
	ld $6,-64(k0)
	ld $7,-72(k0)
	ld $8,-80(k0)
	ld $9,-88(k0)
	ld $10,-96(k0)
	ld $11,-104(k0)
	ld $12,-112(k0)
	ld $13,-120(k0)
	ld $14,-128(k0)
	ld $15,-136(k0)
	ld $16,-144(k0)
	ld $17,-152(k0)
	ld $18,-160(k0)
	ld $19,-168(k0)
	ld $20,-176(k0)
	ld $21,-184(k0)
	ld $22,-192(k0)
	ld $23,-200(k0)
	ld $24,-208(k0)
	ld $25,-216(k0)
	ld $26,-224(k0) /* k0 - any sense in restoring these??? */
	ld $27,-232(k0) /* k1 */
	ld $28,-240(k0)
	ld $29,-248(k0)
	ld $31,-264(k0)
	
	lw $30, -16(k0) /* restore SR */
	mtc0 $30, C0_SR
	nop
	
	ld $30, -272(k0) /* restore LO */
	mtlo $30
	nop
	
	ld $30, -280(k0) /* restore HI */
	mthi $30
	nop

	lw $30, -552(k0) /* restore BadVaddr */
	mtc0 $30, $8
	nop

	lw $30, -560(k0) /* restore EPC */
	mtc0 $30, $14
	nop

	lw $30, -568(k0) /* restore Cause */
	mtc0 $30, $13
	nop

	ldc1 $f0,-296(k0)
	ldc1 $f1,-304(k0)
	ldc1 $f2,-312(k0)
	ldc1 $f3,-320(k0)
	ldc1 $f4,-328(k0)
	ldc1 $f5,-336(k0)
	ldc1 $f6,-344(k0)
	ldc1 $f7,-352(k0)
	ldc1 $f8,-360(k0)
	ldc1 $f9,-368(k0)
	ldc1 $f10,-376(k0)
	ldc1 $f11,-384(k0)
	ldc1 $f12,-392(k0)
	ldc1 $f13,-400(k0)
	ldc1 $f14,-408(k0)
	ldc1 $f15,-416(k0)
	ldc1 $f16,-424(k0)
	ldc1 $f17,-432(k0)
	ldc1 $f18,-440(k0)
	ldc1 $f19,-448(k0)
	ldc1 $f20,-456(k0)
	ldc1 $f21,-464(k0)
	ldc1 $f22,-472(k0)
	ldc1 $f23,-480(k0)
	ldc1 $f24,-488(k0)
	ldc1 $f25,-496(k0)
	ldc1 $f26,-504(k0)
	ldc1 $f27,-512(k0)
	ldc1 $f28,-520(k0)
	ldc1 $f29,-528(k0)
	ldc1 $f30,-536(k0)
	ldc1 $f31,-544(k0)

	ld $30, -288(k0) /* restore FC31 */
	ctc1 $30, $f31
	nop

	ld $30, -256(k0)
	.set noat
	ld $1, -8(k0) /* restore AT */

	/* restore regStackPos */
	lw k0, regStackPos
	li k1, 600
	sub k0, k0, k1
	la k1, regStackPos
	sw  k0, (k1)

	eret
	nop
	.set at
	
.section .bss
	.align 8
//	.lcomm regStack, 4096
	.lcomm regStack, 2048
	.lcomm regStackPos, 4

