/*

	OR1K load/store alignment exception test

	Cause unaligned load/store exceptions

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
	
/*

	gpr1 counts each time we enter the handler.

*/
	
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

	// Alignment error handler.
	// Clobbers r3,r4, increments r1
	// Steps over exception-causing instruction
	.org 0x600

	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get PC of bad jump instruction */
	l.nop 	0x2
	l.addi	r3,r3,4 	/* Step over error instruction */
	l.mtspr	r0,r3,SPR_EPCR_BASE
	l.addi	r1,r1,1		/* Increment exception counter */
	l.or	r3,r1,r0	/* Move counter to r3 to report */
	l.nop 	0x2
	l.rfe


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

	l.movhi	r1,0	/* clear r1 - used as exception handler counter */
	l.movhi	r2,0	/* clear r2 - used as exception main function counter */

	/* Generate some unaligned addresses */
	/* Unaligned word loads, immediates causing alignment error */
	l.lwz	r8,1(r0)
	l.addi	r2,r2,1

	l.lwz	r8,2(r0)
	l.addi	r2,r2,1

	l.lwz	r8,3(r0)
	l.addi	r2,r2,1

	l.lwz	r8,-1(r0)
	l.addi	r2,r2,1
	
	l.lwz	r8,-2(r0)
	l.addi	r2,r2,1

	l.lwz	r8,-3(r0)
	l.addi	r2,r2,1
	

	/* Unaligned word loads, register contents causing alignment error */
	l.ori	r6,r0,0x1
	l.lwz	r6,0(r6)
	l.addi	r2,r2,1

	l.ori	r6,r0,0x2
	l.lwz	r6,0(r6)
	l.addi	r2,r2,1

	l.ori	r6,r0,0x3
	l.lwz	r6,0(r6)
	l.addi	r2,r2,1

	l.ori	r6,r0,0x1
	l.lwz	r6,1(r6)
	l.addi	r2,r2,1

	l.ori	r6,r0,0x2
	l.lwz	r6,1(r6)
	l.addi	r2,r2,1

	l.ori	r6,r0,0x2
	l.lwz	r6,-1(r6)
	l.addi	r2,r2,1

	l.ori	r6,r0,0x3
	l.lwz	r6,-1(r6)
	l.addi	r2,r2,1

	l.ori	r6,r0,0x3
	l.lwz	r6,-2(r6)
	l.addi	r2,r2,1

	/* Unaligned half-word loads */
	l.lhz	r8,1(r0)
	l.addi	r2,r2,1

	l.lhz	r8,-1(r0)
	l.addi	r2,r2,1

	l.lhz	r8,3(r0)
	l.addi	r2,r2,1

	l.lhz	r8,-3(r0)
	l.addi	r2,r2,1

	/* Unaligned word stores, immediates causing alignment error */
	l.sw	1(r0),r0
	l.addi	r2,r2,1

	l.sw	2(r0),r0
	l.addi	r2,r2,1

	l.sw	3(r0),r0
	l.addi	r2,r2,1

	l.sw	-1(r0),r0
	l.addi	r2,r2,1

	l.sw	-2(r0),r0
	l.addi	r2,r2,1

	l.sw	-3(r0),r0
	l.addi	r2,r2,1

	/* Unaligned word stores - both register and immediate cause error*/
	l.ori	r6,r0,0x1
	l.sw	0(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x2
	l.sw	0(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x3
	l.sw	0(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x1
	l.sw	1(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x1
	l.sw	2(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x2
	l.sw	1(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x2
	l.sw	-1(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x3
	l.sw	-1(r6),r0
	l.addi	r2,r2,1

	l.ori	r6,r0,0x3
	l.sw	-2(r6),r0
	l.addi	r2,r2,1

	/* Unaligned half-word stores */
	l.sh	1(r0),r8
	l.addi	r2,r2,1

	l.sh	-1(r0),r8
	l.addi	r2,r2,1

	l.sh	3(r0),r8
	l.addi	r2,r2,1

	l.sh	-3(r0),r8
	l.addi	r2,r2,1


	/* Check tests triggered correct exceptions*/
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

	
