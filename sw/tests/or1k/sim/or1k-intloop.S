#include <or1k-asm.h>
#include "spr-defs.h"
#include "board.h"
	
/*

	User IRQ while looping to self test
	
	Within the test we'll use following global variables:

	r10 irq interrupt counter
	r12 intgen's base address

	The test does the following:
	Preload the interrupt generator to fire while we're sitting and
	looping to self. Make the interrupt vector increment by 1
	instruction and resume.

	Julius Baxter <juliusbaxter@gmail.com>
*/
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2011, 2012 Authors and OPENCORES.ORG           ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
        .org 0x100 	
	l.movhi r0, 0
	/* Clear status register */
	l.ori 	r1, r0, SPR_SR_SM
	l.mtspr r0, r1, SPR_SR
	/* Clear timer  */
	l.mtspr r0, r0, SPR_TTMR
	/* Init the stack */
	.global _stack
	l.movhi r1, hi(_stack)
	l.ori 	r1, r1, lo(_stack)
	l.addi  r2, r0, -3
	l.and   r1, r1, r2
	/* Jump to program initialisation code */
	.global _start
	l.movhi r4, hi(_start)
	l.ori 	r4, r4, lo(_start)
	l.jr    r4
	l.nop

	
/* =================================================== [ User interrupt ] === */
	.org 0x800
	.global _user_irq_handler
_user_irq_handler:
	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get PC of bad instruction */
	l.nop 	0x2
	l.addi	r3,r3,4 	        /* Step over instruction */
	l.mtspr	r0,r3,SPR_EPCR_BASE

	l.addi r10, r10, 1
	/* Report values , 0x00000800 == user interrupt report*/
	l.ori r3, r0, 0x0800
	l.nop 2
	l.or r3, r0, r10
	l.nop 2
	/* TODO - propably confirm it was intgen's IRQ that caused this */
	/* Clear interrupt source */
	l.ori	r7, r12, 0x1 	/* intgen IRQ clear address */
	l.sb	0(r7), r0 	/* Any write clears the bit */
	/* Clear OR1200 PICSR */
	l.mfspr r7, r0, SPR_PICSR
	l.mtspr r0, r7, SPR_PICSR

	l.rfe

/* =================================================== [ text section ] === */
	.section  .text

/* =================================================== [ start ] === */	

	.global _start
_start:	
	// Kick off test
	l.jal   _main
	l.nop

/* =================================================== [ main ] === */	
.global _main
_main:
	
	#
	# unmask (enable) all ints
	#
	l.movhi r5,0xffff
	l.ori   r5,r5,0xffff
	l.mtspr r0,r5,SPR_PICMR		# set PICMR

	/* Enable Interrupts */
        l.mfspr r6,r0,SPR_SR
        l.ori   r6,r6,SPR_SR_IEE
        l.mtspr r0,r6,SPR_SR

	l.movhi r15, 0
	l.movhi r6, 0
	l.movhi r10, 0
	l.movhi	r11, 0 // register to store some calculation values
	// set up r12 to hold intgen's base address
	l.movhi	r12,hi(INTGEN_BASE)
	
#define INTGEN_LOAD(x)	\
	l.ori	r5,r0,lo(x)	;\
	l.sb	0(r12),r5
	
	/* Test begin */
	
	INTGEN_LOAD(2)
	l.j	0
	INTGEN_LOAD(3)
	l.j	0
	INTGEN_LOAD(4)
	l.j	0
	INTGEN_LOAD(5)
	l.j	0
	INTGEN_LOAD(6)
	l.j	0
	INTGEN_LOAD(7)
	l.j	0
	INTGEN_LOAD(8)
	l.j	0
	INTGEN_LOAD(9)
	l.j	0
	INTGEN_LOAD(10)
	l.j	0
	INTGEN_LOAD(11)
	l.j	0
	INTGEN_LOAD(12)
	l.j	0
	INTGEN_LOAD(13)
	l.j	0
	INTGEN_LOAD(14)
	l.j	0
	INTGEN_LOAD(15)
	l.j	0
	INTGEN_LOAD(16)
	l.j	0
	INTGEN_LOAD(17)
	l.j	0
	INTGEN_LOAD(18)
	l.j	0
	INTGEN_LOAD(19)
	l.j	0
	INTGEN_LOAD(20)
	l.j	0
	INTGEN_LOAD(21)
	l.j	0
	INTGEN_LOAD(22)
	l.j	0
	INTGEN_LOAD(23)
	l.j	0
	INTGEN_LOAD(24)
	l.j	0
	INTGEN_LOAD(25)
	l.j	0
	INTGEN_LOAD(26)
	l.j	0
	INTGEN_LOAD(27)
	l.j	0
	INTGEN_LOAD(28)
	l.j	0
	INTGEN_LOAD(29)
	l.j	0
	INTGEN_LOAD(30)
	l.j	0
	INTGEN_LOAD(31)
	l.j	0
	INTGEN_LOAD(32)
	l.j	0
	INTGEN_LOAD(33)
	l.j	0
	INTGEN_LOAD(34)
	l.j	0
	INTGEN_LOAD(35)
	l.j	0
	INTGEN_LOAD(36)
	l.j	0
	INTGEN_LOAD(37)
	l.j	0
	INTGEN_LOAD(38)
	l.j	0
	INTGEN_LOAD(39)
	l.j	0
	INTGEN_LOAD(40)
	l.j	0


	l.sfnei	r10,39
	l.bf _fail
	l.nop
	
	l.movhi r3, hi(0x8000000d)
	l.ori r3, r3, lo(0x8000000d)
	l.nop 2
	l.ori r3, r0, 0
	l.nop 1
	
_fail:
	l.movhi r3, hi(0xbaaaaaad)
	l.ori r3, r3, lo(0xbaaaaaad)
	l.nop 1
