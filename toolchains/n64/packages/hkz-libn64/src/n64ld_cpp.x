/* ========================================================================
 *
 * n64ld.x
 *
 * GNU Linker script for building an image that is set up for the N64
 * but still has the data factored into sections.  It is not directly
 * runnable, and it contains the debug info if available.  It will need
 * a 'loader' to perform the final stage of transformation to produce
 * a raw image.
 *
 * Copyright (c) 1999 Ground Zero Development, All rights reserved.
 * Developed by Frank Somers <frank@g0dev.com>
 * Modifications by hcs (halleyscometsoftware@hotmail.com)
 *
 * $Header: /afs/icequake.net/users/nemesis/n64/sf/asdf/n64dev/lib/alt-libn64/n64ld.x,v 1.2 2006-08-11 15:54:11 halleyscometsw Exp $
 *
 * ========================================================================
 */

OUTPUT_FORMAT ("elf32-bigmips", "elf32-bigmips", "elf32-littlemips")
OUTPUT_ARCH (mips)
EXTERN (_start)
ENTRY (_start)

MEMORY
{
	k0	:	ORIGIN = 0x80000400, LENGTH =  8M-0x0400
	cart	:	ORIGIN = 0xB0001000, LENGTH = 32M-0x1000
}

SECTIONS {
	reloc_start = 0x80000400;
	cart_start = 0xB0001000;
	. = reloc_start;

   .text : {
      __text_start = . ;
	  *(.init)
	  . = ALIGN(4);
	  __after_init = . ;
	  *(.text)
      *(.text.*)
      *(.fini)
	  *(.gnu.linkonce.t.*)
      __text_end  = . ;
   } > k0

   .eh_frame_hdr : { *(.eh_frame_hdr) } > k0
   .eh_frame : { KEEP (*(.eh_frame)) } > k0
   .gcc_except_table : { *(.gcc_except_table*) } > k0
   .jcr : { KEEP (*(.jcr)) } > k0

   .rodata : {
     *(.rdata)
     *(.rodata)
     *(.rodata.*)
     *(.gnu.linkonce.r.*)
   } > k0

   .ctors : {
	  . = ALIGN(8);
 	  __CTOR_LIST__ = .;
	  LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
	    *(.ctors)
	  LONG(0)
	  __CTOR_END__ = .;  	
   } > k0

   .dtors : {
 	  __DTOR_LIST__ = .;
	  LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
 	    *(.dtors)
	  LONG(0)
      __DTOR_END__ = .;
	} > k0

   .data : {
	  . = ALIGN(8);
	  __data_start = . ;
         *(.data)
		 *(.data.*)
		 *(.gnu.linkonce.d.*)
      __data_end = . ;
   } > k0

   . = ALIGN(8);
   _gp = . + 0x8000;

   .lit8 : {
    *(.lit8)
   } > k0
   .lit4 : {
    *(.lit4)
   } > k0

   .sdata : {
    *(.sdata)
    *(.sdata.*)
	*(.gnu.linkonce.s.*)
   } > k0

   . = ALIGN(4);
   .sbss (NOLOAD) : {
	 __sbss_start = . ;
     *(.sbss)
     *(.sbss.*)
	 *(.gnu.linkonce.sb.*)
     *(.scommon)
	 __sbss_end = . ;
   } > k0

   . = ALIGN(4);
   .bss (NOLOAD) : {
    __bss_start = . ;
	*(.bss)
	*(.bss*)
	*(.gnu.linkonce.b.*)
	*(COMMON)
	__bss_end = . ;
   } > k0

   . = ALIGN(8);
	end = .;

	.romfs : {
		. = ALIGN(16);
		QUAD(0x0);
		QUAD(0x524f4d4653000001);
		_romfs = .;
	} > k0
}
