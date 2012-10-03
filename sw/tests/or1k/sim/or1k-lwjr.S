/*

	OR1K load and then jump reg test
	
	Check basic functionality.

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

	Checks that the following sort of sequence executes correctly:
	l.add	r3,r4,r3
	l.lwz	r3,0(r3)
	l.jalr	r3
	l.nop
	

*/
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

	l.movhi	r1,0	/* clear r1 - used as function counter */
	l.movhi	r2,0	/* clear r2 - used as  main loop counter */

	/* get the address for the target function, store it in memory */
	l.movhi	r3, hi(test_func)
	l.ori	r3, r3, lo(test_func)
	l.sw	0x7eec(r0), r3

	/* now let's put 0x7eec in a reg, put it into another and then
	load from that address and jump to the test function */
	l.ori	r4, r0, 0x7eec
	l.or	r3, r0, r0

	/* test sequence */
	l.add	r3, r4, r3
	l.lwz	r3, 0(r3)
	OR1K_DELAYED_NOP(OR1K_INST(l.jalr	r3))
	// Looks like JALR on no delay breaks here!
	/* increment main loop counter */
	l.addi	r2, r2, 1


	l.or	r3, r0, r0
	l.movhi	r9, hi(_L1)
	l.ori	r9, r9, lo(_L1)
	/* test sequence */
	l.add	r3, r4, r3
	l.lwz	r3, 0(r3)
	OR1K_DELAYED_NOP(OR1K_INST(l.jr	r3))

_L1:	
	/* increment main loop counter */
	l.addi	r2, r2, 1

	/* Now test jumping where we would have executed anyway */
	l.or	r3, r0, r0
	l.movhi	r9, hi(_L2)
	l.ori	r9, r9, lo(_L2)
	l.sw	0x7eec(r0), r9
	l.nop
	/* test sequence */
	l.add	r3, r4, r3
	l.lwz	r3, 0(r3)
	OR1K_DELAYED(
	/* increment "called" counter */	
	OR1K_INST(l.addi	r2, r2, 1),
	OR1K_INST(l.jr	r3)
	)
	
_L2:	
	/* increment "arrived" counter */
	l.addi	r1, r1, 1

	l.or	r3,r1,r1
	l.nop	2
	l.or	r3,r2,r2
	l.nop	2
	
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
	OR1K_INST(l.addi	r1, r1, 1),
	OR1K_INST(l.jr	r9)
	)