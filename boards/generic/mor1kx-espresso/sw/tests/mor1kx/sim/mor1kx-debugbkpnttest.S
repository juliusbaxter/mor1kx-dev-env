/*

	mor1kx l.trap (software) breakpoint test code

	This is for the espresso pipeline. It _will_ test
	delay-slot traps.

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


	.org 0x200
	l.nop 0x1
	
	.org 0x500
	l.nop 0x1

	.org 0x600
	l.nop 0x1
	
	.org 0x700
	l.nop 0x1

	.org 0x800
	l.nop 0x1

	.org 0xc00
	l.trap 	0
	l.mfspr	r8, r0, SPR_EPCR_BASE
	l.addi	r8,r8,4
	l.mtspr	r0,r8,SPR_EPCR_BASE
	l.trap	0
	l.rfe
	

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

	/* loop here waiting for the testbench to write a value into
	memory */
	/* start word is 0x80000000 */
	l.movhi	r2, 0x8000
startwait:
	l.lwz	r1, 0x4(r0)
	l.sfne	r1, r2
	OR1K_DELAYED_NOP(OR1K_INST(l.bf	startwait))
	
	l.movhi	r1,0	/* clear r1 */
	l.movhi	r2,0	/* clear r2 */
	l.movhi	r3,0	/* clear r2 */

	l.sys	0
	l.trap	0
	l.sys	0
	l.trap	0
	
	/* some mfspr instructions - test if the control stage can
	step through these properly */
	l.movhi r4, 0xaabb
	l.trap	0
	l.ori	r4, r4, 0xccdd
	l.trap	0
	l.mtspr r0, r4, SPR_TTCR
	l.trap	0
	
	/* now read it back, check it all works */
	l.mfspr	r5, r0, SPR_TTCR
	l.trap	0
	l.sfeq	r4, r5
	l.trap	0	
	OR1K_DELAYED_NOP(OR1K_INST(l.bnf	testfailed))

	/* now call the test function a few ways, ensuring that
	the counter is incremented */

	/* jal - this will make sure the link reg looks good */
	l.trap	0
	l.addi	r3, r3, 1
	l.trap	0
	OR1K_DELAYED_NOP(OR1K_INST(l.jal	testfunc1))

	/* call the function another way */
	l.movhi r2, hi(testfunc1)
	l.trap	0
	l.ori	r2, r2, lo(testfunc1)
	l.trap	0	
	l.movhi r9, hi(return1)
	l.trap	0
	l.ori	r9, r9, lo(return1)
	l.trap	0		
	l.addi	r3, r3, 1
	l.trap	0	
	OR1K_DELAYED_NOP(OR1K_INST(l.jr	r2))

	
return1:
	l.trap	0
	l.nop

	/* Branch to function, return */
	l.movhi r9, hi(return2)
	l.ori	r9, r9, lo(return2)
	l.sfeq	r0, r0 /* Set flag */
	l.addi	r3, r3, 1
	l.trap	0	
	OR1K_DELAYED_NOP(OR1K_INST(l.bf	testfunc1))

return2:
	l.trap	0	
	l.nop

	/* Don't branch to function */
	l.movhi r9, hi(return2)
	l.ori	r9, r9, lo(return2)
	l.sfeq	r0, r0 /* Set flag */
	OR1K_DELAYED_NOP(OR1K_INST(l.bnf	testfunc1))

	/* Branch to function with bnf, return */
	l.movhi r9, hi(return3)
	l.ori	r9, r9, lo(return3)
	l.sfeqi	r0, 1 /* Clear flag */
	l.addi	r3, r3, 1
	OR1K_DELAYED_NOP(OR1K_INST(l.bnf	testfunc1))

return3:
	l.trap	0	
	l.nop

	/* now test traps in delay slots */
delay_slot_jump_tests:	
	l.movhi r2, hi(testfunc2)
	l.ori	r2, r2, lo(testfunc2)
	l.addi	r3, r3, 1
	l.jalr	r2
	l.trap	0

	l.movhi r9, hi(return4)
	l.ori	r9, r9, lo(return4)
	l.sfeq	r0,r0 /* set flag */
	l.addi	r3, r3, 1
	l.bf	testfunc2
	l.trap	0
return4:

	l.movhi r9, hi(return5)
	l.ori	r9, r9, lo(return5)
	l.sfeq	r0,r9 /* clear flag */
	l.addi	r3, r3, 1
	l.bnf	testfunc2
	l.trap	0
return5:

	l.movhi r9, hi(return6)
	l.ori	r9, r9, lo(return6)
	l.addi	r3, r3, 1
	l.j	testfunc2
	l.trap	0
return6:

	l.movhi r9, hi(return7)
	l.ori	r9, r9, lo(return7)
	l.addi	r3, r3, 1
	l.jr	r2
	l.trap	0
return7:
	
testresultcheck:
	l.sfeq	r1, r3 /* check the function call counters match */
	OR1K_DELAYED_NOP(OR1K_INST(l.bnf	testfailed))	/* they didn't */


testfinishcheck:
	/* should have the word 0x8000000d at address 0x4 if we're to finish */
	l.ori	r15, r0, 0x4
	l.lwz 	r3, 0(r15)
	l.nop 	0x2
	l.movhi r14, 0x8000
	l.ori	r14, r14, 0x000d

	l.sfeq	r3,r14
	/* if the word is not there, keep checking */
	OR1K_DELAYED_NOP(OR1K_INST(l.bnf	testfinishcheck))


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
	OR1K_DELAYED_NOP(OR1K_INST(l.jr	r9))

testfunc2:
	l.addi	r1, r1,1
	l.jr	r9
	l.trap  0 /* Trap in delay slot! */
	
	