#include <or1k-asm.h>
#include "spr-defs.h"
#include "board.h"
	
/*

	Tick timer and l.j 0 looping
	
	Within the test we'll use following global variables:

	r17 timer interrupt counter


	The test do the following:
	Setup tick interrupts to occur, and then loop waiting for
	a certain number of interrupts to occur, before setting EPCR to
	beyond the loop instruction.

	Julius Baxter, julius@opencores.org
*/
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2010, 2012 Authors and OPENCORES.ORG           ////
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


#define TICK_COUNTER_VALUE 32



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
	l.addi 	r17, r17, 1
	l.sfeqi r17,64
	l.bnf	_test_not_finished
	l.nop
	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get PC of bad instruction */
	l.nop 	0x2
	l.addi	r3,r3,8 	        /* Step over instruction */
	l.mtspr	r0,r3,SPR_EPCR_BASE
_test_not_finished:
# Set r7 to hold value of TTMR, one-shot mode/single run (SR)
	l.addi 	r5, r0, TICK_COUNTER_VALUE /* Tick timer counter value */
	l.movhi r6,hi(SPR_TTMR_SR | SPR_TTMR_IE)
	l.add  	r7,r5,r6
	/* Report values , 0x00000500 == tick timer report*/
	l.ori 	r3, r0, 0x0500
	l.nop 	2
	l.or 	r3, r0, r17
	l.nop 	2
# Init the tick timer
	l.mtspr r0,r0,SPR_TTCR 		# clear TTCR
	l.mtspr r0,r7,SPR_TTMR		# set TTMR
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
	l.movhi r15, 0
	l.movhi r16, 0
	l.movhi r17, 0
	
	#
	# unmask all ints
	#
	l.movhi r5,0xffff
	l.ori   r5,r5,0xffff
	l.mtspr r0,r5,SPR_PICMR		# set PICMR
	
	# Set r20 to hold enable exceptions and interrupts
	l.mfspr	r20,r0,SPR_SR
	l.ori r20,r20,SPR_SR_SM|SPR_SR_TEE
	
	# Enable exceptions and interrupts
	l.mtspr r0,r20,SPR_SR	# set SR
	
	# Set r7 to hold value of TTMR, one-shot mode/single run (SR)
	l.addi r5, r0, TICK_COUNTER_VALUE /* Tick timer counter value */
	l.movhi r6,hi(SPR_TTMR_SR | SPR_TTMR_IE)
	l.add  r7,r5,r6
	
	# Init the tick timer
	l.mtspr r0,r0,SPR_TTCR 		# clear TTCR
	l.mtspr r0,r7,SPR_TTMR		# set TTMR
	
_wait_loop:
	l.j	0
	l.nop
	l.nop
	l.nop
	
finish:	
	l.movhi r3, hi(0x8000000d)
	l.ori r3, r3, lo(0x8000000d)
	l.nop 2
	l.ori r3, r0, 0
	l.nop 1
