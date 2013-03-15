/*

	OR1K timer test
	
	Check basic functionality.

	Currently only checks single-shot mode.

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
	l.jr    r4
	l.nop

	// Tick handler
	.org 0x500
	/* Clear interrupt pending bit */
	l.mfspr	r11,r0, SPR_TTMR
	l.movhi	r12, hi(SPR_TTMR_IP)
	l.xor	r11, r11, r12
	l.mtspr	r0, r11, SPR_TTMR
	/* check which test we're doing */
	l.sfltui r10, 3
	OR1K_DELAYED(
	/* increment exception counter regardless of test */
	OR1K_INST(l.addi	r2, r2, 1),
	OR1K_INST(l.bf	timer_rfe))
	/* only clear the ttmr for test 3 */
	l.mtspr r0,r0,SPR_TTMR
timer_rfe:
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
	
	l.movhi	r1,0	/* clear r1 - used as main loop counter */
	l.movhi	r2,0	/* clear r2 - used as exception handler counter */
	l.movhi	r10,0   /* clear r10 - used to indicate the test */

	/* First check auto-restart timer */
	l.addi	r10, r10, 1

	/* enable timer interrupts, clear timer mode reg */
	l.mfspr	r3, r0, SPR_SR
	l.ori 	r3, r3, SPR_SR_TEE
	l.mtspr r0, r0, SPR_TTMR
	l.mtspr	r0, r3, SPR_SR

	/* Restart timer causing interrupt */
	l.movhi r4,hi(SPR_TTMR_RT | SPR_TTMR_IE)
	/* interrupt after 200 cycles */
	l.ori	r6, r0, 200
	
	/* load timer */
	l.or	r5,r4,r6 /* value we'll interrupt on */
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR
	l.mtspr r0,r5,SPR_TTMR		# set TTMR
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR

	/* loop checking r2 which will be incremented on interrupt */
restart_timer_interrupt_check:
	l.sfeq	r2, r0
	OR1K_DELAYED(
	OR1K_INST(l.mfspr	r4, r0, SPR_TTCR),
	l.bf	restart_timer_interrupt_check
	)

	l.sfltu	r4, r6 /* timer should have reset and counting again */
	OR1K_DELAYED(
	OR1K_INST(l.mfspr	r5, r0, SPR_TTCR),
	OR1K_INST(l.bnf	test_fail)
	)

	l.sfleu	r5, r4 /* timer should still be going */
	OR1K_DELAYED_NOP(l.bf 	test_fail)

	l.mtspr r0,r0,SPR_TTMR /* clear ttmr, turn it off */

	/* Continuous run check */
	l.addi	r10, r10, 1
	
	l.movhi	r1,0	/* clear r1 - used as main loop counter */
	l.movhi	r2,0	/* clear r2 - used as exception handler counter */

	/* First check auto-restart timer */

	/* enable timer interrupts, clear timer mode reg */
	l.mfspr	r3, r0, SPR_SR
	l.ori 	r3, r3, SPR_SR_TEE
	l.mtspr r0, r0, SPR_TTMR
	l.mtspr	r0, r3, SPR_SR

	/* Restart timer causing interrupt */
	l.movhi r4,hi(SPR_TTMR_CR | SPR_TTMR_IE)
	/* interrupt after 200 cycles */
	l.ori	r6, r0, 200
	
	/* load timer */
	l.or	r5,r4,r6 /* value we'll interrupt on */
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR
	l.mtspr r0,r5,SPR_TTMR		# set TTMR
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR

	/* loop checking r2 which will be incremented on interrupt */
continuous_timer_interrupt_check:
	l.sfeq	r2, r0
	OR1K_DELAYED_NOP(l.bf	continuous_timer_interrupt_check)
	
	l.mfspr	r4, r0, SPR_TTCR

	l.sfltu	r4, r6 /* timer should have continued again */
	OR1K_DELAYED(
	OR1K_INST(l.mfspr	r5, r0, SPR_TTCR),
	OR1K_INST(l.bf	test_fail)
	)	
	l.sfleu	r5, r4 /* timer should still be going */
	OR1K_DELAYED_NOP(l.bf 	test_fail)

	l.mtspr r0,r0,SPR_TTMR /* clear ttmr, turn it off */

	/* single shot, but also do some testing of timer interrupts and
	system during lots of timer interrupts */
	l.addi	r10, r10, 1


	/* enable timer interrupts, clear timer mode reg */
	l.mfspr	r3, r0, SPR_SR
	l.ori 	r3, r3, SPR_SR_TEE
	l.mtspr r0, r0, SPR_TTMR
	l.mtspr	r0, r3, SPR_SR

	/* Single shot timer causing interrupt */
	l.movhi r4,hi(SPR_TTMR_SR | SPR_TTMR_IE)
	
	/* r6 - timer ticks until interrupt */
	l.ori	r6, r0, 10

	l.movhi	r1,0	/* clear r1 - used as main loop counter */
	l.movhi	r2,0	/* clear r2 - used as exception handler counter */
	

#define TIMER_MAIN_LOOPS 200

one_shot_main_loop:
	l.sfgeui r6, TIMER_MAIN_LOOPS
	OR1K_DELAYED(
	OR1K_INST(l.or 	r3, r6, r6),
	OR1K_INST(l.bf	check_results)
	)

	/* check if the results match so far */
	l.sfeq	r1,r2
	OR1K_DELAYED(
	OR1K_INST(l.nop 0x2),
	OR1K_INST(l.bnf	test_fail)
	)

	/*setup timer to go, loop until we should have had tick */
	
	/* load timer */
	l.or	r5,r4,r6 /* value we'll interrupt on */
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR
	l.mtspr r0,r5,SPR_TTMR		# set TTMR
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR

	/* increment the main loop tick interrupt counter */
	l.addi	r1, r1, 1

	l.sfgeui r6, 200
	OR1K_DELAYED(
	/* start our instruction counter loop */	
	OR1K_INST(l.ori	r7,r0,2),
	OR1K_INST(l.bf	longer_interrupt_loop)
	)	
	
interrupt_loop:
	l.sfltu	r7, r6
	OR1K_DELAYED(
	OR1K_INST(l.addi	r7, r7, 3),
	OR1K_INST(l.bf	interrupt_loop)
	)
	/* loop done, increment main loop counter */
	OR1K_DELAYED(
	OR1K_INST(l.addi	r6, r6, 1),
	OR1K_INST(l.j	one_shot_main_loop)
	)

longer_interrupt_loop:
	l.sw	0x4(r0), r7
	l.lwz	r8, 0x4(r0)
	l.sfne	r7, r8
	OR1K_DELAYED(
	OR1K_INST(l.addi r7, r7, 4),
	OR1K_INST(l.bf	test_fail)
	)
	l.sw	0x4(r0), r7
	l.lwz	r8, 0x4(r0)
	l.sfne	r7, r8
	OR1K_DELAYED(
	OR1K_INST(l.addi r7, r7, 4),
	OR1K_INST(l.bf	test_fail)
	)
	l.sw	0x4(r0), r7
	l.lwz	r8, 0x4(r0)
	l.sfne	r7, r8
	OR1K_DELAYED(
	OR1K_INST(l.addi	r7, r7, 4),
	OR1K_INST(l.bf	test_fail)
	)

	l.sw	0x4(r0), r7
	l.lwz	r8, 0x4(r0)
	l.sfne	r7, r8
	OR1K_DELAYED(
	OR1K_INST(l.addi	r7, r7, 4),
	OR1K_INST(l.bf	test_fail)
	)
	l.sfltu	r7, r6
	OR1K_DELAYED(
	OR1K_INST(l.addi	r7, r7, 3),
	OR1K_INST(l.bf	longer_interrupt_loop)
	)
	/* loop done, increment main loop counter */
	OR1K_DELAYED(
	OR1K_INST(l.addi	r6, r6, 1),
	OR1K_INST(l.j	one_shot_main_loop)
	)
	
check_results:	
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

