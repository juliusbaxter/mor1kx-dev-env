/*

	mor1kx debug exception step test code

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
	l.jr    r4
	l.nop

	.org 0x200
	l.mfspr	r9, r0, SPR_EPCR_BASE
	l.addi	r9, r9, 4
	l.mtspr	r0, r9, SPR_EPCR_BASE
	l.addi	r3, r3, 1
	l.rfe
	
	.org 0x500
	l.addi	r3, r3, 1
	l.rfe


	.org 0x600
	l.mfspr	r9, r0, SPR_EPCR_BASE
	l.addi	r9, r9, 4
	l.mtspr	r0, r9, SPR_EPCR_BASE
	l.addi	r3, r3, 1
	l.rfe

	
	.org 0x700
	l.mfspr	r9, r0, SPR_EPCR_BASE
	l.addi	r9, r9, 4
	l.mtspr	r0, r9, SPR_EPCR_BASE
	l.addi	r3, r3, 1
	l.rfe

	.org 0x800
	l.nop	0x1


/* =================================================== [ text ] === */
	.section .text

/* =================================================== [ start ] === */	

	.global _start
_start:	
	// Kick off test
	l.jal   _main
	l.nop
	


/* =================================================== [ main ] === */
	
	.global _main	
_main:

	/* loop here waiting for the testbench to write a value into
	memory */
	/* start word is 0x80000000 */
	l.movhi	r2, 0x8000
startwait:
	l.lwz	r1, 0x8(r0)
	l.sfne	r1, r2
	l.bf	startwait
	
	l.movhi	r1,0	/* clear r1 */
	l.movhi	r2,0	/* clear r2 */
	l.movhi	r3,0	/* clear r2 */

	/* Test bus error */
	l.movhi	r4, hi(0xee000000)
	/* first call */
	l.addi	r1, r1, 1
	l.jr	r4

	/* second call */
	l.addi	r1, r1, 1
	l.jr	r4

	/* Test lsu error */
	l.movhi	r4, hi(0xee000000)
	/* first call */
	l.addi	r1, r1, 1
	l.lwz	r8, 0(r4)

	/* second call */
	l.addi	r1, r1, 1
	l.lwz	r8, 0(r4)

	/* Test align error */
	l.movhi	r4, hi(0xee000000)
	/* first call */
	l.addi	r1, r1, 1
	l.lwz	r8, 1(r4)

	/* second call */
	l.addi	r1, r1, 1
	l.lwz	r8, 3(r4)

	/* Illegal instruction */
	l.cust1
	l.addi	r1, r1, 1

	
testresultcheck:
	l.sfeq	r1, r3 /* check the function call counters match */
	l.bnf	testfailed	/* they didn't */

testfinishcheck:
	/* should have the word 0x8000000d at address 0x4 if we're to finish */
	l.ori	r15, r0, 0x4
	l.lwz 	r3, 0(r15)
	l.nop 	0x2
	l.movhi r14, 0x8000
	l.ori	r14, r14, 0x000d

	l.sfeq	r3,r14
	/* if the word is not there, keep checking */
	l.bnf	testfinishcheck

testok:
	l.nop 	0x2
	l.ori 	r3, r0, 0
	l.nop 	0x1

testfailed:
	l.movhi r3, 0xbaaa
	l.ori	r3, r3, 0xaaad
	l.nop 	0x1
	
testfunc1:
	l.addi	r1, r1,1
	l.jr	r9

	