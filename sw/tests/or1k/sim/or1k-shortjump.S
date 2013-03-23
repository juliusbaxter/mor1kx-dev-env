/*

	OR1K short jump ahead test
	
	Test jumping to 0, 1, 2 and 3 instructions ahead

	Then enable tick timer to interrupt it relatively frequently
	and redo the tests.

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
	
	// Timer exception, clear interrupt bit, and return
	.org 0x500
	l.mfspr	r11,r0, SPR_TTMR
	l.movhi	r12, hi(SPR_TTMR_IP)
	l.xor	r11, r11, r12
	l.mtspr	r0, r11, SPR_TTMR
	l.addi	r13,r13,1
	l.rfe

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



/* Test macros - performing jumps for each instruction we can */

#ifdef __OR1K_DELAY__

	/* A set of macros to perform short jumps, manipulating
	counters along the way to ensure each instruction gets
	executed. */
	
        .macro  short_j_0
	l.addi	r1,r1,1
        l.j	1f
	l.addi	r2,r2,2
1:	
	l.addi	r2,r2,-1
	.endm

        .macro  short_jr_0
	l.addi	r1,r1,1
	l.movhi	r4,hi(1f)
	l.ori	r4,r4,lo(1f)
        l.jr	r4
	l.addi	r2,r2,2
1:	
	l.addi	r2,r2,-1
	.endm

        .macro  short_jalr_0
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,8
1:	
        l.jalr	r4
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm
	
        .macro  short_jal_0
	l.addi	r1,r1,1
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,8
1:	
        l.jal	2f
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm

	.macro  short_j_1
	l.addi	r1,r1,1
        l.j	1f
	l.addi	r2,r2,2
	l.nop
1:	
	l.addi	r2,r2,-1
	.endm

        .macro  short_jr_1
	l.addi	r1,r1,1
	l.movhi	r4,hi(1f)
	l.ori	r4,r4,lo(1f)
        l.jr	r4
	l.addi	r2,r2,2
	l.nop
1:	
	l.addi	r2,r2,-1
	.endm
	
        .macro  short_jalr_1
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,8
1:	
        l.jalr	r4
	l.nop
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm

        .macro  short_jal_1
	l.addi	r1,r1,1
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,8
1:	
        l.jal	2f
	l.nop
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm

	
	.macro  short_j_2
	l.addi	r1,r1,1
        l.j	1f
	l.addi	r2,r2,2
	l.nop
	l.nop
1:	
	l.addi	r2,r2,-1
	.endm

        .macro  short_jr_2
	l.addi	r1,r1,1
	l.movhi	r4,hi(1f)
	l.ori	r4,r4,lo(1f)
        l.jr	r4
	l.addi	r2,r2,2
	l.nop
	l.nop
1:	
	l.addi	r2,r2,-1
	.endm

        .macro  short_jalr_2
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,8
1:	
        l.jalr	r4
	l.nop
	l.nop
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm
	
        .macro  short_jal_2
	l.addi	r1,r1,1
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,8
1:	
        l.jal	2f
	l.nop
	l.nop
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm


        .macro  jump_jump_jump
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r6,hi(6f)
	l.ori	r6,r6,lo(6f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,8
1:	
        l.jalr	r4
	l.nop
	l.nop
	l.nop
2:	
	l.sfne	r5,r9
	l.bf	test_fail
	l.j	3f
	l.addi	r1,r1,1
3:
	l.j	4f
	l.addi	r1,r1,-1
	l.nop
4:	
	l.j	5f
	l.addi	r1,r1,1
	l.nop
	l.nop
5:	
	l.jr	r6
	l.addi	r1,r1,-1
6:	
	l.addi	r2,r2,1
	.endm

	
#else

        .macro  short_j_0
	l.addi	r1,r1,1
        l.j	1f
1:	
	l.addi	r2,r2,1
	.endm

        .macro  short_jr_0
	l.addi	r1,r1,1
	l.movhi	r4,hi(1f)
	l.ori	r4,r4,lo(1f)
        l.jr	r4
1:	
	l.addi	r2,r2,1
	.endm

        .macro  short_jalr_0
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,4
1:	
        l.jalr	r4
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm

        .macro  short_jal_0
	l.addi	r1,r1,1
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,4
1:	
        l.jal	2f
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm

	
	.macro  short_j_1
	l.addi	r1,r1,1
        l.j	1f
	l.nop
1:	
	l.addi	r2,r2,1
	.endm

        .macro  short_jr_1
	l.addi	r1,r1,1
	l.movhi	r4,hi(1f)
	l.ori	r4,r4,lo(1f)
        l.jr	r4
	l.nop
1:	
	l.addi	r2,r2,1
	.endm

        .macro  short_jalr_1
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,4
1:	
        l.jalr	r4
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm

        .macro  short_jal_1
	l.addi	r1,r1,1
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,4
1:	
        l.jal	2f
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm
	
	
	.macro  short_j_2
	l.addi	r1,r1,1
        l.j	1f
	l.nop
	l.nop
1:	
	l.addi	r2,r2,1
	.endm

        .macro  short_jr_2
	l.addi	r1,r1,1
	l.movhi	r4,hi(1f)
	l.ori	r4,r4,lo(1f)
        l.jr	r4
	l.nop
	l.nop
1:	
	l.addi	r2,r2,1
	.endm
	

        .macro  short_jalr_2
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,4
1:	
        l.jalr	r4
	l.nop
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm

        .macro  short_jal_2
	l.addi	r1,r1,1
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,4
1:	
        l.jal	2f
	l.nop
	l.nop
2:	
	l.addi	r2,r2,1
	l.sfne	r5,r9
	l.bf	test_fail
	.endm


        .macro  jump_jump_jump
	l.addi	r1,r1,1
	l.movhi	r4,hi(2f)
	l.ori	r4,r4,lo(2f)
	l.movhi	r6,hi(6f)
	l.ori	r6,r6,lo(6f)
	l.movhi	r5,hi(1f)
	l.ori	r5,r5,lo(1f)
	l.addi	r5,r5,4
1:	
        l.jalr	r4
	l.nop
	l.nop
2:	
	l.sfne	r5,r9
	l.bf	test_fail
	l.j	3f
3:
	l.j	4f
	l.nop
4:	
	l.j	5f
	l.nop
	l.nop
5:	
	l.jr	r6
6:	
	l.addi	r2,r2,1
	.endm
	
#endif	



	
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
	
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	short_j_0
	
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1
	short_j_1

	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2
	short_j_2

	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	short_jr_0
	
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1
	short_jr_1

	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2
	short_jr_2

	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	short_jalr_0
	
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1
	short_jalr_1

	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2
	short_jalr_2

	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	short_jal_0
	
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1
	short_jal_1

	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2
	short_jal_2

	jump_jump_jump
	jump_jump_jump
	jump_jump_jump
	jump_jump_jump
	jump_jump_jump
	jump_jump_jump
	jump_jump_jump
	jump_jump_jump
	jump_jump_jump
	jump_jump_jump

	/* Check results OK */
	l.sfeq	r1,r2
	l.bf	test_ok

test_fail:	
	l.movhi	r3,0xbaaa
	l.ori	r3,r3,0xaaad
	l.nop	0x1

test_ok:
	/* Rerun test with timers enabled if we have them */
	l.mfspr r2,r0,SPR_UPR
	l.andi 	r2,r2,SPR_UPR_TTP
	l.sfeq	r2,r0
	l.bf	test_finish
	l.nop
	/* We do have timers, in this case check it it's enabled yet */
	l.mfspr	r2,r0,SPR_SR
	l.andi	r2,r2,SPR_SR_TEE
	l.sfeq 	r2,r0
	/* we've not run through with timers so enable them and restart */
	l.bf	enable_timers_and_restart
	l.nop

test_finish:
	/* report interrupts */
	l.or	r3,r13,r13
	l.nop	0x2
	l.movhi	r3,0x8000
	l.ori	r3,r3,0x000d
	l.nop	0x2
	l.ori 	r3, r0, 0 /* Clear R3 */
	l.nop 	0x1 /* Exit simulation */
	l.nop
	l.nop

enable_timers_and_restart:

	/* enable timer interrupts in SR, clear timer mode reg */
	l.mfspr	r3, r0, SPR_SR
	l.ori 	r3, r3, SPR_SR_TEE
	l.mtspr r0, r0, SPR_TTMR
	l.mtspr	r0, r3, SPR_SR

	/* Setup timer mode register to run in restart mode, with interrupts */
	l.movhi r4,hi(SPR_TTMR_RT | SPR_TTMR_IE)
	/* interrupt every 40 cycles */
	l.ori	r6, r0, 40
	
	/* load timer */
	l.or	r5,r4,r6 /* value we'll interrupt on */
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR
	l.mtspr r0,r5,SPR_TTMR		# set TTMR
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR

	/* clear r13, tick interrupt counter */
	l.movhi	r13, 0
	
	l.j	_main
	l.nop