/*

	OR1K pipeline result forwarding with timer exceptions test.

	Attempts to recreate a bug where the register forwarding logic may
	behave incorrectly when being interrupted
	
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

	// Tick handler
	.org 0x500
	l.addi	r1,r1,1
	/* Clear interrupt pending bit */
	l.mfspr	r11,r0, SPR_TTMR
	l.movhi	r12, hi(SPR_TTMR_IP)
	l.xor	r11, r11, r12
	l.mtspr	r0, r11, SPR_TTMR
	/* increment exception counter */
	l.addi	r2, r2, 1
	/* report nop */
	l.ori	r3,r2,0
	l.nop 0x2

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

       /*
        * initiate r20 with a known value, when the bug occurs
        * r1 will contain this value
        */
       l.movhi r20,0xbaaa
       l.ori   r20,r20,0xaaad
	

	/* First check auto-restart timer */
	l.addi	r10, r10, 1

	/* enable timer interrupts, clear timer mode reg */
	l.mfspr	r3, r0, SPR_SR
	l.ori 	r3, r3, SPR_SR_TEE
	l.mtspr r0, r0, SPR_TTMR
	l.mtspr	r0, r3, SPR_SR

	/* Restart timer causing interrupt */
	l.movhi r4,hi(SPR_TTMR_RT | SPR_TTMR_IE)
	/* interrupt after 40 cycles */
	l.ori	r6, r0, 60
	
	/* load timer */
	l.or	r5,r4,r6 /* value we'll interrupt on */
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR
	l.mtspr r0,r5,SPR_TTMR		# set TTMR
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR

	/* loop checking r2 which will be incremented on interrupt */
	l.movhi	r1,0
	l.movhi	r2,0
restart_timer_interrupt_check:

#define EIGHTADDS() 	\
	l.addi	r1,r1,4 	; \
	l.sw    0(r0),r20       ; \
	l.lwz   r20,0(r0)       ; \
	l.addi	r1,r1,4 	; \
	l.addi	r1,r1,4 	; \
	l.addi	r1,r1,4 	; \
	l.addi	r1,r1,4 	; \
	l.addi	r1,r1,4 	; \
	l.addi	r1,r1,4 	; \
	l.addi	r1,r1,4		; \
	l.or	r3,r1,r1	; \
	l.nop 0x2 		;
	
#define SIXTYFOURADDS() \
	EIGHTADDS() \
	EIGHTADDS() \
	EIGHTADDS() \
	EIGHTADDS() \
	EIGHTADDS() \
	EIGHTADDS() \
	EIGHTADDS() \
	EIGHTADDS() 

#define FIVETWELVEADDS() \
	SIXTYFOURADDS() \
	SIXTYFOURADDS() \
	SIXTYFOURADDS() \
	SIXTYFOURADDS() \
	SIXTYFOURADDS() \
	SIXTYFOURADDS() \
	SIXTYFOURADDS() \
	SIXTYFOURADDS()

#define FOURKADDS()		\
	FIVETWELVEADDS()	; \
	FIVETWELVEADDS()	; \
	FIVETWELVEADDS()	; \
	FIVETWELVEADDS()	; \
	FIVETWELVEADDS()	; \
	FIVETWELVEADDS()	; \
	FIVETWELVEADDS()	; \
	FIVETWELVEADDS()	;

	//SIXTYFOURADDS()
	FOURKADDS()
	
check_results:
	l.mtspr r0,r0,SPR_TTMR /* clear ttmr, turn it off */
	l.ori	r3,r1,0
	l.nop 0x2
	/* Check results OK */
	/* r1 should = 4k*4 + r2*1 */
	l.addi  r2, r2, (4096*4)
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

