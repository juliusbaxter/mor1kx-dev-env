#include <or1k-asm.h>
#include "spr-defs.h"
#include "board.h"

#define NUM_TICKS_FOR_TEST 1024
#define TICK_COUNTER_VALUE 48
#define INT_WAIT_BOUNDS_MIN 8
#define INT_WAIT_BOUNDS_MAX 128

	
/*

	User IRQ and tick timer while looping to self
	
	Within the test we'll use following global variables:

	r10 irq interrupt counter
	r12 intgen's base address
	r13 tick timer counter
	
	The test does the following:
	Preload the interrupt generator to fire while we're sitting and
	looping to self. Make the interrupt vector increment by 1
	instruction and resume.
	Also make the tick timer go off regularly.

	What ends up happening is tick and IRQ interrupts occuring
	simultaneously, so it checks that l.rfe from one exception
	straight into another works as intended.

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

/* =================================================== [ tick interrupt ] === */
	.org 0x500
	.global _tick_handler
_tick_handler:
	
	l.addi 	r13, r13, 1
# Set r7 to hold value of TTMR, one-shot mode/single run (SR)
	l.addi 	r8, r0, TICK_COUNTER_VALUE /* Tick timer counter value */
	l.movhi r6,hi(SPR_TTMR_SR | SPR_TTMR_IE)
	l.add  	r7,r8,r6
	/* Report values , 0x00000500 == tick timer report*/
	l.ori 	r3, r0, 0x0500
	l.nop 	2
	l.or 	r3, r0, r13
	l.nop 	2
# Init the tick timer
	l.mtspr r0,r0,SPR_TTCR 		# clear TTCR
	l.mtspr r0,r7,SPR_TTMR		# set TTMR
	l.rfe
	
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
	/* Clear PICSR */
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

	// Use r7 to hold value of TTMR, one-shot mode/single run (SR)
	l.addi r5, r0, TICK_COUNTER_VALUE /* Tick timer counter value */
	l.movhi r6,hi(SPR_TTMR_SR | SPR_TTMR_IE)
	l.add  r7,r5,r6

	# Init the tick timer
	l.mtspr r0,r0,SPR_TTCR 		# clear TTCR
	l.mtspr r0,r7,SPR_TTMR		# set TTMR
	
	/* Enable Interrupts */
        l.mfspr r6,r0,SPR_SR
        l.ori   r6,r6,(SPR_SR_IEE | SPR_SR_TEE)
        l.mtspr r0,r6,SPR_SR

	# Init the tick timer
	l.mtspr r0,r0,SPR_TTCR 		# clear TTCR
	l.mtspr r0,r7,SPR_TTMR		# set TTMR

	
	l.movhi r15, 0
	l.movhi r6, 0
	l.movhi r10, 0
	l.movhi	r11, 0 // register to store some calculation values
	// set up r12 to hold intgen's base address
	l.movhi	r12,hi(INTGEN_BASE)
	l.movhi	r13, 0 // tick counter register

// r2 will record how many interrupts we generated via the intgen guy
// r5 will hold the value of the current interrupt delay value
// r4 will hold whether we're incrementing or decrementing (1 or -1)
	l.movhi	r2,0
	l.ori	r5,r0,INT_WAIT_BOUNDS_MIN
	l.addi	r4,r0,1
	
int_loop_start:
	l.addi	r2,r2,1
	// Load the interrupt module with its value
	l.sb	0(r12),r5
	// Now sit and wait
	l.j	0
	// This code should be OK for CPUs with and without delay slots

check_irq_delay_bounds:	
	// Now check if the IRQ delay value is at its max or min
	l.sfltui r5, INT_WAIT_BOUNDS_MAX
	l.bf	under_max
	l.nop
	// At max, switch to decrement
	l.addi	r4,r0,-1
	l.movhi	r3,0x2222
	l.nop	2
	l.j check_if_finished
	l.nop

under_max:
	// Are we still within the range?
	l.sfgtui r5, INT_WAIT_BOUNDS_MIN
	l.bf	check_if_finished
	l.nop
	// Otherwise it's at minimum, switch to incrementing
	l.addi	r4,r0,1
	l.movhi	r3,0x1111
	l.nop	2
	l.j	check_if_finished
	l.nop

check_if_finished:
	// Have we done all of our timer loops?
	l.sfgtui r13, NUM_TICKS_FOR_TEST
	l.bf finished
	
update_irq_delay:
	l.add	r5,r5,r4
	// restart
	l.j	int_loop_start
	l.nop

finished:
	// Disable tick timer
	l.mtspr r0,r0,SPR_TTMR
	
	// Make sure that for every interrupt we asked to generate, that
	// we actually serviced it.
	l.or r3, r0, r10
	l.nop 2
	l.or r2, r0, r10
	l.nop 2
	
	l.sfne	r10,r2
	l.bf fail
	l.nop
	
	l.movhi r3, hi(0x8000000d)
	l.ori r3, r3, lo(0x8000000d)
	l.nop 2
	l.ori r3, r0, 0
	l.nop 1
	
fail:
	l.movhi r3, hi(0xbaaaaaad)
	l.ori r3, r3, lo(0xbaaaaaad)
	l.nop 1
