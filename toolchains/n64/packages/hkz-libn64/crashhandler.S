
#include "regs.S"

.globl crash_handler
.globl fatal_error_handler
.set noreorder

fatal_error_handler:
	move v0, a0

	/* Prepare background color */
	jal draw_crash_background
	nop

	li a3, 0xF800

	/* Print TITLE */
	la a0, error_title
	li a1, 80 /* X */
	li a2, 21 /* Y */
	jal print_string
	nop

	li a3, 0xFFFE

	/* Print error message */
	move a0, v0
	li a1, 21
	li a2, 60
	jal print_string
	nop

	/* Heap end */
	la a0, heap
	li a1, 150
	li a2, 197
	jal print_string
	nop
	li a0, 0
	jal sbrk
	nop
	move a0, v0
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 184
	li a2, 197
	jal print_string
	nop

	/* Init video interface and show screen */
	jal init_video_interface
	nop

	loop_assert:
	j loop_assert
	nop

crash_handler:
	/* Prepare background color */
	jal draw_crash_background
	nop

	li a3, 0xF800 /* Pixel colour for title */

	/* Print TITLE */
	la a0, crash_title
	li a1, 48 /* X */
	li a2, 21 /* Y */
	jal print_string
	nop

	li a3, 0xFFFE

	/* Memory size */
	la a0, memsize
	li a1, 22
	li a2, 35
	jal print_string
	nop
	lw a0, 0x80000318
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 105
	li a2, 35
	jal print_string
	nop

	lw v1, regStackPos

	/* v0 */
	la a0, regv0
	li a1, 22
	li a2, 50
	jal print_string
	nop
	ld a0, -32(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 50
	jal print_string
	nop

	/* v1 */
	la a0, regv1
	li a1, 22
	li a2, 59
	jal print_string
	nop
	ld a0, -40(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 59
	jal print_string
	nop

	/* a0 */
	la a0, rega0
	li a1, 22
	li a2, 68
	jal print_string
	nop
	ld a0, -48(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 68
	jal print_string
	nop

	/* a1 */
	la a0, rega1
	li a1, 22
	li a2, 76
	jal print_string
	nop
	ld a0, -56(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 76
	jal print_string
	nop

	/* a2 */
	la a0, rega2
	li a1, 22
	li a2, 85
	jal print_string
	nop
	ld a0, -64(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 85
	jal print_string
	nop

	/* a3 */
	la a0, rega3
	li a1, 22
	li a2, 94
	jal print_string
	nop
	ld a0, -72(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 94
	jal print_string
	nop

	/* t0 */
	la a0, regt0
	li a1, 22
	li a2, 103
	jal print_string
	nop
	ld a0, -80(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 103
	jal print_string
	nop

	/* t1 */
	la a0, regt1
	li a1, 22
	li a2, 112
	jal print_string
	nop
	ld a0, -88(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 112
	jal print_string
	nop

	/* t2 */
	la a0, regt2
	li a1, 22
	li a2, 121
	jal print_string
	nop
	ld a0, -96(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 121
	jal print_string
	nop

	/* t3 */
	la a0, regt3
	li a1, 22
	li a2, 130
	jal print_string
	nop
	ld a0, -104(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 130
	jal print_string
	nop

	/* t4 */
	la a0, regt4
	li a1, 22
	li a2, 139
	jal print_string
	nop
	ld a0, -112(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 139
	jal print_string
	nop

	/* t5 */
	la a0, regt5
	li a1, 22
	li a2, 148
	jal print_string
	nop
	ld a0, -120(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 148
	jal print_string
	nop

	/* t6 */
	la a0, regt6
	li a1, 22
	li a2, 157
	jal print_string
	nop
	ld a0, -128(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 157
	jal print_string
	nop

	/* t7 */
	la a0, regt7
	li a1, 22
	li a2, 166
	jal print_string
	nop
	ld a0, -136(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 166
	jal print_string
	nop

	/* s0 */
	la a0, regs0
	li a1, 22
	li a2, 175
	jal print_string
	nop
	ld a0, -144(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 48
	li a2, 175
	jal print_string
	nop

	/* s1 */
	la a0, regs1
	li a1, 150
	li a2, 50
	jal print_string
	nop
	ld a0, -152(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 50
	jal print_string
	nop

	/* s2 */
	la a0, regs2
	li a1, 150
	li a2, 59
	jal print_string
	nop
	ld a0, -160(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 59
	jal print_string
	nop

	/* s3 */
	la a0, regs3
	li a1, 150
	li a2, 68
	jal print_string
	nop
	ld a0, -168(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 68
	jal print_string
	nop

	/* s4 */
	la a0, regs4
	li a1, 150
	li a2, 77
	jal print_string
	nop
	ld a0, -176(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 77
	jal print_string
	nop

	/* s5 */
	la a0, regs5
	li a1, 150
	li a2, 86
	jal print_string
	nop
	ld a0, -184(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 86
	jal print_string
	nop

	/* s6 */
	la a0, regs6
	li a1, 150
	li a2, 95
	jal print_string
	nop
	ld a0, -192(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 95
	jal print_string
	nop

	/* s7 */
	la a0, regs7
	li a1, 150
	li a2, 104
	jal print_string
	nop
	ld a0, -200(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 104
	jal print_string
	nop

	/* t8 */
	la a0, regt8
	li a1, 150
	li a2, 113
	jal print_string
	nop
	ld a0, -208(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 113
	jal print_string
	nop

	/* t9 */
	la a0, regt9
	li a1, 150
	li a2, 122
	jal print_string
	nop
	ld a0, -216(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 122
	jal print_string
	nop

	/* k0 */
	la a0, regk0
	li a1, 150
	li a2, 131
	jal print_string
	nop
	ld a0, -224(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 131
	jal print_string
	nop

	/* k1 */
	la a0, regk1
	li a1, 150
	li a2, 140
	jal print_string
	nop
	ld a0, -232(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 140
	jal print_string
	nop

	/* gp */
	la a0, reggp
	li a1, 150
	li a2, 149
	jal print_string
	nop
	ld a0, -240(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 149
	jal print_string
	nop

	/* sp */
	la a0, regsp
	li a1, 150
	li a2, 158
	jal print_string
	nop
	ld a0, -248(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 158
	jal print_string
	nop

	/* fp */
	la a0, regfp
	li a1, 150
	li a2, 167
	jal print_string
	nop
	ld a0, -256(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 167
	jal print_string
	nop

	li a3, 0xF780 /* Yellow for RA */

	/* ra */
	la a0, regra
	li a1, 150
	li a2, 176 
	jal print_string
	nop
	ld a0, -264(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 176
	jal print_string
	nop

	li a3, 0xFFFE

	/* at */
	la a0, regat
	li a1, 150
	li a2, 185 
	jal print_string
	nop
	ld a0, -8(v1)
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 176
	li a2, 185
	jal print_string
	nop

	/* Cause */
	la a0, cause
	li a1, 22
	li a2, 197
	jal print_string
	nop
	mfc0 a0, $13
	nop
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 56
	li a2, 197
	jal print_string
	nop

	li a3, 0xC000 /* Red colour for cause */

	/* Cause print */
	li a1, 150
	li a2, 197
	mfc0 a0, $13
	nop
	srl	a0, a0, 2
	and	a0, a0, 31 // Keep last 5 bits
	
	beq a0, 0, excp_00
	nop
	beq a0, 1, excp_01
	nop
	beq a0, 2, excp_02
	nop
	beq a0, 3, excp_03
	nop
	beq a0, 4, excp_04
	nop
	beq a0, 5, excp_05
	nop
	beq a0, 6, excp_06
	nop
	beq a0, 7, excp_07
	nop
	beq a0, 8, excp_08
	nop
	beq a0, 9, excp_09
	nop
	beq a0, 10, excp_10
	nop
	beq a0, 11, excp_11
	nop
	beq a0, 12, excp_12
	nop
	beq a0, 13, excp_13
	nop
	beq a0, 14, excp_14
	nop
	beq a0, 15, excp_15
	nop
	beq a0, 16, excp_16
	nop
	beq a0, 17, excp_17
	nop
	beq a0, 18, excp_18
	nop
	beq a0, 19, excp_19
	nop
	beq a0, 20, excp_20
	nop
	beq a0, 21, excp_21
	nop
	beq a0, 22, excp_22
	nop
	beq a0, 23, excp_23
	nop
	beq a0, 24, excp_24
	nop
	beq a0, 25, excp_25
	nop
	beq a0, 26, excp_26
	nop
	beq a0, 27, excp_27
	nop
	beq a0, 28, excp_28
	nop
	beq a0, 29, excp_29
	nop
	beq a0, 30, excp_30
	nop
	beq a0, 31, excp_31
	nop

	excp_00:
	    la a0, ex00
	    b print_cause
	nop
	excp_01:
		la a0, ex01
		b print_cause
	nop
	excp_02:
		la a0, ex02
		b print_cause
	nop
	excp_03:
		la a0, ex03
		b print_cause
	nop
	excp_04:
		la a0, ex04
		b print_cause
	nop
	excp_05:
		la a0, ex05
		b print_cause
	nop
	excp_06:
		la a0, ex06
		b print_cause
	nop
	excp_07:
		la a0, ex07
		b print_cause
	nop
	excp_08:
		la a0, ex08
		b print_cause
	nop
	excp_09:
		la a0, ex09
		b print_cause
	nop
	excp_10:
		la a0, ex10
		b print_cause
	nop
	excp_11:
		la a0, ex11
		b print_cause
	nop
	excp_12:
		la a0, ex12
		b print_cause
	nop
	excp_13:
		la a0, ex13
		b print_cause
	nop
	excp_14:
		la a0, ex14
		b print_cause
	nop
	excp_15:
		la a0, ex15
		b print_cause
	nop
	excp_16:
		la a0, ex16
		b print_cause
	nop
	excp_17:
		la a0, ex17
		b print_cause
	nop
	excp_18:
		la a0, ex18
		b print_cause
	nop
	excp_19:
		la a0, ex19
		b print_cause
	nop
	excp_20:
		la a0, ex20
		b print_cause
	nop
	excp_21:
		la a0, ex21
		b print_cause
	nop
	excp_22:
		la a0, ex22
		b print_cause
	nop
	excp_23:
		la a0, ex23
		b print_cause
	nop
	excp_24:
		la a0, ex24
		b print_cause
	nop
	excp_25:
		la a0, ex25
		b print_cause
	nop
	excp_26:
		la a0, ex26
		b print_cause
	nop
	excp_27:
		la a0, ex27
		b print_cause
	nop
	excp_28:
		la a0, ex28
		b print_cause
	nop
	excp_29:
		la a0, ex29
		b print_cause
	nop
	excp_30:
		la a0, ex30
		b print_cause
	nop
	excp_31:
		la a0, ex31
		b print_cause
	nop


	print_cause:
	jal print_string
	nop

	li a3, 0xF780 /* Yellow for EPC */

	/* EPC */
	la a0, epc
	li a1, 22
	li a2, 188
	jal print_string
	nop
	mfc0 a0, $14
	nop
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 56
	li a2, 188
	jal print_string
	nop

	li a3, 0xFFFE

	/* BadVaddr */
	la a0, badvadd
	li a1, 22 
	li a2, 206
	jal print_string
	nop
	mfc0 a0, $8
	nop
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 56
	li a2, 206
	jal print_string
	nop

	/* Heap end */
	la a0, heap
	li a1, 150
	li a2, 206
	jal print_string
	nop
	li a0, 0
	jal sbrk
	nop
	move a0, v0
	jal number_to_hex
	nop
	la a0, hex_string
	li a1, 184
	li a2, 206
	jal print_string
	nop

	/* Init video interface and show screen */
	jal init_video_interface
	nop

	loop_crash:
	j loop_crash
	nop

/* DRAW BACKGROUND */

draw_crash_background:
	/* Save needed vars in stack */
	sub sp, sp, 104
	sd a0, 96(sp)
	sd a1, 88(sp)
	sd a2, 80(sp)
	sd a3, 72(sp)
	sd ra, 64(sp)
	sd t7, 56(sp)
	sd t6, 48(sp)
	sd t5, 40(sp)
	sd t4, 32(sp)
	sd t3, 24(sp)
	sd t2, 16(sp)
	sd t1, 8(sp)
	sd t0, 0(sp)

	li	 t0, 0x13880 /* Number of pixels */
	li	 t2, 0xA0020000 /* Framebuffer address */

	li   t3, 0 /* Current line */
	li   t4, 0 /* Current column */
	li   t5, 320 /* Line width */

	color_death_loop:

	/* Calculate screen pixel position */
	add  t4, t4, 1
	beq	 t4, t5, end_screen_line
	nop
	
	/* Draw the pixel */
	begin_pixel_draw:
	
	b check_borders /* Load appropriate color if we are at screen borders */
	nop

	pixel_draw:
	sh	 t1, (t2)
	add  t2, t2, 2 /* Each pixel is 2 bytes in this mode */
	sub  t0, t0, 1 /* One less remaining pixel */

	bnez t0, color_death_loop
	nop	

	/* Destroy stack */
	ld a0, 96(sp)
	ld a1, 88(sp)
	ld a2, 80(sp)
	ld a3, 72(sp)
	ld ra, 64(sp)
	ld t7, 56(sp)
	ld t6, 48(sp)
	ld t5, 40(sp)
	ld t4, 32(sp)
	ld t3, 24(sp)
	ld t2, 16(sp)
	ld t1, 8(sp)
	ld t0, 0(sp)	
	addi sp, sp, 104
	j	ra /* End of function */
	nop

	end_screen_line:
	li t4, 0 /* Back to first column */
	add t3, t3, 1
	b begin_pixel_draw
	nop

	check_borders:
	li t6, 20
	bgt t6, t3, bright_blue /* line < 20  */
	nop

	li t6, 220
	bgt t3, t6, bright_blue /* line > 220  */
	nop

	li t6, 20
	bgt t6, t4, bright_blue /* column < 20 */
	nop

	li t6, 300
	bgt t4, t6, bright_blue /* column > 300 */
	nop
	
	li t1, 0x001E  /* DARK BLUE */
	b pixel_draw
	nop
	bright_blue:
	li t1, 0x003E  /* BLUE */
	b pixel_draw
	nop

/* INITIALIZE AND SHOW SCREEN */

init_video_interface:
	li	 $8, 0xA4400000
	
	li	 $9, 0x01030002
	sw	 $9, ($8)
	addi $8, $8, 4
			                     
	li   $9, 0xA0020000
	sw   $9, ($8)
	addi $8, $8, 4
			                    
	li   $9, 0x00000140
	sw   $9, ($8)
	addi $8, $8, 4
								
	li   $9, 0x000001F2
	sw   $9, ($8)
	addi $8, $8, 4
								  
	li   $9, 0x80000000
	sw   $9, ($8)
	addi $8, $8, 4
								  
	li   $9, 0x03E52239
	sw   $9, ($8)      
	addi $8, $8, 4
								 
	li   $9, 0x0000020D
	sw   $9, ($8)
	addi $8, $8, 4
			
	li   $9, 0x80000C15
	sw   $9, ($8)
	addi $8, $8, 4
								 
	li   $9, 0x0C150C15
	sw   $9, ($8)
	addi $8, $8, 4
								 
	li   $9, 0x006C02EC
	sw   $9, ($8)
	addi $8, $8, 4

	li   $9, 0x002501FF
	sw   $9, ($8)
	addi $8, $8, 4

	li   $9, 0x000E0204
	sw   $9, ($8)
	addi $8, $8, 4
					
	li   $9, 0x00000200
	sw   $9, ($8)       
	addi $8, $8, 4
								 
	li   $9, 0x00000400
	sw   $9, ($8)
	addi $8, $8, 4

	j ra
	nop

/* *** */

/* Prints a character at specified position
 * a0 -> pointer to memory where the char is stored
 * a1 -> X pixel start pos
 * a2 -> Y pixel start pos
 * a3 -> pixel colour
 * It uses an 8x8 font.
 */
print_char:
	/* Save needed vars in stack */
	sub sp, sp, 104
	sd a0, 96(sp)
	sd a1, 88(sp)
	sd a2, 80(sp)
	sd a3, 72(sp)
	sd ra, 64(sp)
	sd t7, 56(sp)
	sd t6, 48(sp)
	sd t5, 40(sp)
	sd t4, 32(sp)
	sd t3, 24(sp)
	sd t2, 16(sp)
	sd t1, 8(sp)
	sd t0, 0(sp)

	la t0, VI_fontdata /* Pointer to font data */
	lbu t1, (a0) /* load the char ascii num into memory */
	
	li t2, 0xA0020000

	/* Reach screen address where we draw */
	move t3, a1
	sll t3, 1
	add t2, t2, t3  /* Reach column */
	move t3, a2
	mul t3, t3, 640 
	add t2, t2, t3  /* Reach line */
	sub t3, t3, 16

	/* Reach letter position in font data */
	sll t1, t1, 3   /* (t1 * 8), because we are using (8*8) font */
	add t0, t0, t1  /* Reach begin of letter */

	li t6, 8
	print_char_line:
	   li t5, 8
	   lb t4, (t0)
	   print_char_column:
		  andi t7, t4, 0x80      
		  
		  beqz t7, nothing_to_draw
		  nop
 
		  sh a3, (t2)

		  nothing_to_draw:
		  sll t4, t4, 1 /* next column */
	      add t2, t2, 2
	      sub t5, t5, 1
	   bnez t5, print_char_column
	   nop
	   add t0, t0, 1 /* next line */
   	   add t2, t2, (640 - 16)
	   sub t6, t6, 1
	bnez t6, print_char_line
	nop


	/* Destroy stack */
	ld a0, 96(sp)
	ld a1, 88(sp)
	ld a2, 80(sp)
	ld a3, 72(sp)
	ld ra, 64(sp)
	ld t7, 56(sp)
	ld t6, 48(sp)
	ld t5, 40(sp)
	ld t4, 32(sp)
	ld t3, 24(sp)
	ld t2, 16(sp)
	ld t1, 8(sp)
	ld t0, 0(sp)	
	addi sp, sp, 104
	j ra
	nop

/* *** */

/* Prints a string at the specified position
 * a0 -> Beginning of '\0' terminated string
 * a1 -> X position on screen
 * a2 -> Y position on screen
 * a3 -> pixel colour
 */
print_string:
	/* Save needed vars in stack */
	sub sp, sp, 104
	sd a0, 96(sp)
	sd a1, 88(sp)
	sd a2, 80(sp)
	sd a3, 72(sp)
	sd ra, 64(sp)
	sd t7, 56(sp)
	sd t6, 48(sp)
	sd t5, 40(sp)
	sd t4, 32(sp)
	sd t3, 24(sp)
	sd t2, 16(sp)
	sd t1, 8(sp)
	sd t0, 0(sp)

	move t2, a1
	move t3, a0

	move t4, a1 /* Save start X pos into t4 */
	li	t5, 0x0A /* newline ascii code */

	lbu t1, (t3)
	print_cycle:

	move a0, t3
	move a1, t2
	jal print_char
	nop

	add t2, t2, 8
sub_print_string_fetch_char:
	add t3, t3, 1
	lbu t1, (t3)
	beq	t1, t5, sub_print_string_newline
	nop
	bnez t1, print_cycle
	nop

	/* Destroy stack */
	ld a0, 96(sp)
	ld a1, 88(sp)
	ld a2, 80(sp)
	ld a3, 72(sp)
	ld ra, 64(sp)
	ld t7, 56(sp)
	ld t6, 48(sp)
	ld t5, 40(sp)
	ld t4, 32(sp)
	ld t3, 24(sp)
	ld t2, 16(sp)
	ld t1, 8(sp)
	ld t0, 0(sp)	
	addi sp, sp, 104
	j ra
	nop

/* Increments to a newline */
sub_print_string_newline:
	move t2, t4 /* Back at the beginning of line */
	add a2, a2, 8 /* new line */
	j sub_print_string_fetch_char
	nop

/* Converts the value in a0 to an hex string
 * placed in hex_string.
 *
 * a0 -> value to convert
 */
number_to_hex:
	/* Save needed vars in stack */
	sub sp, sp, 104
	sd a0, 96(sp)
	sd a1, 88(sp)
	sd a2, 80(sp)
	sd a3, 72(sp)
	sd ra, 64(sp)
	sd t7, 56(sp)
	sd t6, 48(sp)
	sd t5, 40(sp)
	sd t4, 32(sp)
	sd t3, 24(sp)
	sd t2, 16(sp)
	sd t1, 8(sp)
	sd t0, 0(sp)

	la t0, hex_string

	li t1, 48 // '0'
	sb t1, (t0)
	add t0, t0, 1

	li t1, 120 // 'x'
	sb t1, (t0)
	add t0, t0, 1

	li t7, 10
	li t3, 8 
	num_to_char:

	move t6, t3
	sub t6, t6, 1

	sll t4, t6, 2
	move t5, a0
	srl t5, t5, t4

	and t5, t5, 0x0F

	bgeu t5, t7, letter
	nop
	add t5, t5, 48
	b save_char
	nop
	letter:
	add t5, t5, 55

	save_char:
	sb t5, (t0)
	add t0, t0, 1

	sub t3, t3, 1
	bnez t3, num_to_char
	nop

	li t1, 0 // '\0'
	sb t1, (t0)
	add t0, t0, 1

	/* Destroy stack */
	ld a0, 96(sp)
	ld a1, 88(sp)
	ld a2, 80(sp)
	ld a3, 72(sp)
	ld ra, 64(sp)
	ld t7, 56(sp)
	ld t6, 48(sp)
	ld t5, 40(sp)
	ld t4, 32(sp)
	ld t3, 24(sp)
	ld t2, 16(sp)
	ld t1, 8(sp)
	ld t0, 0(sp)	
	addi sp, sp, 104	
	j ra
	nop


error_title:	.asciiz "FATAL ERROR!"
crash_title:	.asciiz "NINTENDO64 EXCEPTION HANDLER"
reset:	.asciiz "[Push RESET]"

heap:	.asciiz "HEA:"
cause:	.asciiz "CAU:"
epc:	 .asciiz "EPC:"
memsize: .asciiz "TOTAL RAM:"
badvadd: .asciiz "BV :"

regat:	.asciiz "AT:"
regv0:	.asciiz "V0:"
regv1:  .asciiz "V1:"
rega0:  .asciiz "A0:"
rega1:  .asciiz "A1:"
rega2:  .asciiz "A2:"
rega3:  .asciiz "A3:"
regt0:	.asciiz "T0:"
regt1:	.asciiz "T1:"
regt2:	.asciiz "T2:"
regt3:	.asciiz	"T3:"
regt4:	.asciiz	"T4:"
regt5:	.asciiz	"T5:"
regt6:	.asciiz	"T6:"
regt7:	.asciiz	"T7:"
regs0:	.asciiz "S0:"
regs1:	.asciiz	"S1:"
regs2:	.asciiz	"S2:"
regs3:	.asciiz	"S3:"
regs4:	.asciiz	"S4:"
regs5:	.asciiz	"S5:"
regs6:	.asciiz	"S6:"
regs7:	.asciiz	"S7:"
regt8:	.asciiz	"T8:"
regt9:	.asciiz	"T9:"
regk0:	.asciiz	"K0:"
regk1:	.asciiz	"K1:"
reggp:	.asciiz	"GP:"
regsp:	.asciiz	"SP:"
regfp:	.asciiz	"FP:"
regra:	.asciiz	"RA:"

/* Exceptions types */
ex00:	.asciiz "Interrupt"
ex01:	.asciiz	"TLB mod"
ex02:	.asciiz "TLB lo/ins fetch"
ex03:	.asciiz	"TLB store"
ex04:	.asciiz	"Addr lo/ins fetch"
ex05:	.asciiz "Addr store"
ex06:	.asciiz	"Bus err (inst)"
ex07:	.asciiz	"Bus err (data)"
ex08:	.asciiz	"Syscall"
ex09:	.asciiz	"Breakpoint"
ex10:	.asciiz	"Reserved instr"
ex11:	.asciiz	"Coproc. Unusable"
ex12:	.asciiz	"Arithm. overflow"
ex13:	.asciiz	"Unk 13"
ex14:	.asciiz	"Unk 14"
ex15:	.asciiz	"FPU exception"
ex16:	.asciiz	"Unk 16"
ex17:	.asciiz	"Unk 17"
ex18:	.asciiz	"Unk 18"
ex19:	.asciiz	"Unk 19"
ex20:	.asciiz	"Unk 20"
ex21:	.asciiz	"Unk 21"
ex22:	.asciiz	"Unk 22"
ex23:	.asciiz	"Unk 23"
ex24:	.asciiz	"Unk 24"
ex25:	.asciiz	"Unk 25"
ex26:	.asciiz	"Unk 26"
ex27:	.asciiz	"Unk 27"
ex28:	.asciiz	"Unk 28"
ex29:	.asciiz	"Unk 29"
ex30:	.asciiz	"Unk 30"
ex31:	.asciiz	"Unk 31"


.section .bss
	.lcomm hex_string, 128
