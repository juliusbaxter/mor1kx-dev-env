/*

	OR1K short branch ahead test
	
	Test branching to 0, 1, 2 and 3 instructions past the delay slot

	Julius Baxter, julius@opencores.org

	
*/
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2011 Authors and OPENCORES.ORG                 ////
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
	
#include <or1k-asm.h>	
#include "spr-defs.h"

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

	/* Jump to program initialisation code */
	.global _start
	l.movhi r4, hi(_start)
	l.ori 	r4, r4, lo(_start)
	OR1K_DELAYED_NOP(OR1K_INST(l.jr    r4))
	

	// Illegal instruction handler
	.org 0x700
	l.movhi	r3,0xbaaa
	l.ori	r3,r3,0xaaad
	l.nop	1
	
	// Trap handler
	.org 0xe00
	l.movhi	r3,0xbaaa
	l.ori	r3,r3,0xaaad
	l.nop	1

/* =================================================== [ text ] === */
	.section .text

/* =================================================== [ start ] === */	

	.global _start
_start:	
	// Kick off test
	OR1K_DELAYED_NOP(OR1K_INST(l.jal   _main))

/* =================================================== [ main ] === */
	
	.global _main	
_main:

	l.movhi	r1,0	/* clear r1 - used as branch counter */
	l.movhi	r2,0	/* clear r2 - used as the result counter */
	l.ori	r3, r0, 1 /* set r3 to 1, if l.nop 1 is hit we don't pass */
	
	/* set flag, will always branch with l.bf */
	l.sfeq	r0,r0

#ifdef __OR1K_DELAY__
	
#define NONE_PAST_DELAY_SLOT_TEST	\
	l.addi	r1, r1, 1	;\
	l.bf	0x8		;\
	l.nop			;\
	l.addi	r2, r2, 1	

#define ONE_PAST_DELAY_SLOT_TEST	\
	l.addi	r1, r1, 1	;\
	l.bf	0xc		;\
	l.nop			;\
	l.nop	0x1		;\
	l.addi	r2, r2, 1	

#define TWO_PAST_DELAY_SLOT_TEST	\
	l.addi	r1, r1, 1	;\
	l.bf	0x10		;\
	l.nop			;\
	l.nop	0x1		;\
	l.nop	0x1		;\
	l.addi	r2, r2, 1	

#else

#define NONE_PAST_DELAY_SLOT_TEST	\
	l.addi	r1, r1, 1	;\
	l.bf	0x4		;\
	l.addi	r2, r2, 1	

#define ONE_PAST_DELAY_SLOT_TEST	\
	l.addi	r1, r1, 1	;\
	l.bf	0x8		;\
	l.nop	0x1		;\
	l.addi	r2, r2, 1	

#define TWO_PAST_DELAY_SLOT_TEST	\
	l.addi	r1, r1, 1	;\
	l.bf	0xc		;\
	l.nop	0x1		;\
	l.nop	0x1		;\
	l.addi	r2, r2, 1	
	
#endif
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	NONE_PAST_DELAY_SLOT_TEST
	
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST
	ONE_PAST_DELAY_SLOT_TEST

	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST
	TWO_PAST_DELAY_SLOT_TEST

	/* Check results OK */
	l.sfeq	r1,r2
	l.bf	test_ok

test_fail:	
	l.movhi	r3,0xbaaa
	l.ori	r3,r3,0xaaad
	l.nop	0x1

test_ok:
	l.movhi	r3,0x8000
	l.ori	r3,r3,0x000d
	l.nop	0x2
	l.ori 	r3, r0, 0 /* Clear R3 */
	l.nop 	0x1 /* Exit simulation */
	l.nop
	l.nop

	.org 0x100000
test_func:
	OR1K_DELAYED(
	OR1K_INST(l.addi r1, r1, 1),
	OR1K_INST(l.jr	r9)
	)
