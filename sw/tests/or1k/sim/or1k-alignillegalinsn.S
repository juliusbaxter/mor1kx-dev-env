/*
	Exception test.

	The following list outlines the tests performed
	
	Execption tests for:
	- 0x100 reset                        - start addr after reset 
	- 0x200 bus error                    - unimplemented addr is accessed
	- 0x600 alignment                    - write to unaligned addr
	- 0x700 illegal instruction          - use unimplemented inst. l.div 
	
	r11 - 1st exception counter incremented inside exception 
	r12 - 2nd exception counter incremented outside and rigth after
	      exception
	... other register use to be documented...

	Julius Baxter, julius@opencores.org
	Tadej Markovic, tadej@opencores.org
	
*/
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2010 Authors and OPENCORES.ORG                 ////
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
#include "board.h"
	
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
	.global stack
	l.movhi r1, hi(stack)
	l.ori 	r1, r1, lo(stack)
	l.addi  r2, r0, -3
	l.and   r1, r1, r2
	/* Jump to program initialisation code */
	.global _start
	l.movhi r4, hi(_start)
	l.ori 	r4, r4, lo(_start)
	l.jr    r4
	l.nop

  
/* ---[ 0x200: BUS error ]------------------------------------------------ */
	.org 0x200
	.global	_bus_handler
	
_bus_handler:
	l.ori	r7,r0,1		/* set "exception flag" */
	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get EPC */
	l.nop	2
	l.mfspr	r3,r0,SPR_EEAR_BASE	/* Get EEA */
	l.nop	2
	l.addi	r11,r11,1		/* Increment 1st exception counter */
	l.sfeqi r2, 0xd /* Is this a data bus test, if so return with l.rfe */
	OR1K_DELAYED(
	OR1K_INST(l.movhi r5, 0),    /* r5 should be the one causing the error on dbus */
	OR1K_INST(l.bf 	1f)
	)
	/* Instruction bus error test return */
	l.movhi r5, hi(0x44004800) /* Put "l.jr r9" instruction in r5 */
	l.ori 	r5, r5, lo(0x44004800)
	l.sw 	0x0(r0), r5 /* Write "l.j r9" to address 0x0 in RAM */
	l.movhi	r5,0x1500	/* Put a "l.nop"  instruction in r5 */
	l.sw	0x4(r0),r5	/* Write l.nop instruction to RAM addr 0x4 */
	l.mtspr	r0,r0,SPR_ICBIR		/* Invalidate line 0 of cache */
	l.mtspr	r0,r0,SPR_EPCR_BASE	/* RFE to 0x0, which is l.jr r9 */
1:	l.rfe

/* ---[ 0x600: ALIGN error ]------------------------------------------------ */
	.org 0x600
	.global	_align_handler
_align_handler:	
	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get EPC */
	l.nop	2
	l.addi	r11,r11,1		/* Increment 1st exception counter */
	l.movhi	r5,0			/* Clear the pointer register */
	l.rfe


/* ---[ 0x700: ILLEGAL INSN exception ]------------------------------------- */
	.org 0x700
	.global _illinsn_handler
_illinsn_handler:
	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get EPC */
	l.nop	2
	l.addi	r11,r11,1		/* Increment 1st exception counter */
#ifdef __OR1K_DELAY__
	/* Delay slot test needs this instruction "fixed" */
	l.movhi	r5,0x1500		/* Put a "l.nop"  instruction in r5 */
	l.sw	0x4(r0),r5	/* Write l.nop instruction to RAM addr 0x4 */
	l.mtspr	r0,r0,SPR_ICBIR		/* Invalidate line 0 of cache */
#endif
	l.mtspr	r0,r0,SPR_EPCR_BASE	/* Jump to 0, which is l.jr r9 */
	l.rfe

/* ---[ 0x900: DTLB exception ]--------------------------------------------- */
	.org 0x900
	l.nop 0x1


/* =================================================== [ text section ] === */
	.section  .text

/* =================================================== [ start ] === */	

	.global _start
_start:	
	l.jal 	_cache_init
	l.nop
	// Kick off test
	l.jal   _main
	l.nop

/* ========================================================= [ main ] === */

	.global	_main
_main:		
	l.nop	
        l.addi	r3,r0,0
        l.addi	r5,r0,0
        l.addi	r11,r0,0 /* exception counter 1 */
        l.addi	r12,r0,0 /* exception counter 2 */
        l.addi	r13,r0,0
	l.addi	r14,r0,0 /* DMMU exception counter for low mem mapping */
	l.addi	r15,r0,0 /* DMMU exception counter for hi mem mapping */
	l.sw	0x0(r0),r0	/* Initialize RAM */	
	l.sw	0x4(r0),r0	/* Initialize RAM */	
	l.sw	0x8(r0),r0	/* Initialize RAM */	
	l.sw	0xc(r0),r0	/* Initialize RAM */	
	l.sw	0x10(r0),r0	/* Initialize RAM */	
	l.sw	0x14(r0),r0	/* Initialize RAM */	
	l.sw	0x18(r0),r0	/* Initialize RAM */	
	l.sw	0x1c(r0),r0	/* Initialize RAM */	
	l.sw	0x20(r0),r0	/* Initialize RAM */	
	l.sw	0x24(r0),r0	/* Initialize RAM */	
	l.sw	0x28(r0),r0	/* Initialize RAM */	
	l.sw	0x2c(r0),r0	/* Initialize RAM */	
	l.sw	0x30(r0),r0	/* Initialize RAM */	
	l.sw	0x34(r0),r0	/* Initialize RAM */	
	l.sw	0x38(r0),r0	/* Initialize RAM */	
	l.sw	0x3c(r0),r0	/* Initialize RAM */	
	l.sw	0x40(r0),r0	/* Initialize RAM */	
	l.sw	0x44(r0),r0	/* Initialize RAM */	
	l.sw	0x48(r0),r0	/* Initialize RAM */	
	l.sw	0x4c(r0),r0	/* Initialize RAM */	
	l.j	_align1
	l.nop


        /* Exceptions followed by NOPs */

	/* SW alignment exception */
_align1:	
	l.movhi r11,0
	l.nop
	/* Test l.sh */
	l.ori 	r5,r0,0x1 /* Half-word access, offset 1 */
	l.sh 	0x0(r5),r0
	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x3 /* Half-word access, offset 3 */
	l.sh 	0x0(r5),r0
	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	/* Test l.lhz */
	l.ori 	r5,r0,0x1 /* Half-word access, offset 1 */
	l.lhz	r3,0x0(r5)
	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x3 /* Half-word access, offset 3 */
	l.lhz 	r3,0x0(r5)
	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	/* Test l.lhs */
	l.ori 	r5,r0,0x1 /* Half-word access, offset 1 */
	l.lhs 	r3,0x0(r5)
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x3 /* Half-word access, offset 3 */
	l.lhs	r3,0x0(r5)	
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	/* Test l.sw */
	l.ori	r5,r0,0x1 /* Word access, offset 1 */	
	l.sw	0x0(r5), r0
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x2 /* Word access, offset 2 */	
	l.sw	0x0(r5), r0
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x3 /* Word access, offset 3 */	
	l.sw	0x0(r5), r0
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	/* Test l.lwz */
	l.ori	r5,r0,0x1 /* Word access, offset 1 */	
	l.lwz	r3,0x0(r5)
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x2 /* Word access, offset 2 */	
	l.lwz	r3,0x0(r5)
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x3 /* Word access, offset 3 */	
	l.lwz	r3,0x0(r5)
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	/* Test l.lws */
	l.ori	r5,r0,0x1 /* Word access, offset 1 */	
	l.lws	r3,0x0(r5)
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x2 /* Word access, offset 2 */	
	l.lws	r3,0x0(r5)
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x3 /* Word access, offset 3 */	
	l.lws	r3,0x0(r5)	
	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.nop

#ifdef __OR1K_DELAY__
	/* Now test them in delay slots */
	l.ori	r5,r0,0x1 /* Half-word access, offset 1 */
	l.j	1f  
	l.sh	0x0(r5),r0
	l.nop
1:	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x3 /* Half-word access, offset 3 */
	l.j	2f  	
	l.sh	0x0(r5),r0
	l.nop	
2:	l.addi	r12,r12,1 /* Increment 2nd exception counter */

	/* Test l.lhz */
	l.ori	r5,r0,0x1 /* Half-word access, offset 1 */
	l.j	3f
	l.lhz	r3,0x0(r5)
	l.nop	
3:	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x3 /* Half-word access, offset 3 */
	l.j	4f
	l.lhz	r3,0x0(r5)
	l.nop
4:	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	
	/* Test l.lhs */
	l.ori	r5,r0,0x1 /* Half-word access, offset 1 */
	l.j	5f
	l.lhs	r3,0x0(r5)
	l.nop	
5:	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	l.ori	r5,r0,0x3 /* Half-word access, offset 3 */
	l.j	6f
	l.lhs	r3,0x0(r5)
	l.nop
6:	l.addi	r12,r12,1 /* Increment 2nd exception counter */
	
	/* Test l.sw */
	l.ori 	r5,r0,0x1 /* Word access, offset 1 */     
	l.j 	7f
	l.sw 	0x0(r5), r0
	l.nop	
7:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x2 /* Word access, offset 2 */     
	l.j 	8f
	l.sw 	0x0(r5), r0
	l.nop	
8:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x3 /* Word access, offset 3 */     
	l.j 	9f
	l.sh 	0x0(r5), r0
	l.nop
9:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */

	/* Test l.lwz */
	l.ori 	r5,r0,0x1 /* Word access, offset 1 */
	l.j 	10f
	l.lwz 	r3,0x0(r5)
	l.nop
10:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x2 /* Word access, offset 2 */
	l.j 	11f
	l.lwz 	r3,0x0(r5)
	l.nop
11:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x3 /* Word access, offset 3 */
	l.j 	12f
	l.lwz 	r3,0x0(r5)
	l.nop
12:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */

	/* Test l.lws */
	l.ori 	r5,r0,0x1 /* Word access, offset 1 */
	l.j 	13f
	l.lws 	r3,0x0(r5)
	l.nop
13:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x2 /* Word access, offset 2 */
	l.j 	14f
	l.lws 	r3,0x0(r5)
	l.nop
14:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */
	l.ori 	r5,r0,0x3 /* Word access, offset 3 */
	l.j 	15f
	l.lws 	r3,0x0(r5)
	l.nop
15:	l.addi 	r12,r12,1 /* Increment 2nd exception counter */

#endif
	
	/* Check 1st and 2nd exception counters are equal */
	l.sfeq	r11,r12			/* Should be equal */
	l.bf	17f
	l.nop
	l.nop	1
17:	l.nop	2
	l.nop

	/* Illegal instruction exception */
_illegal1:	
	l.nop
	l.nop
	l.movhi r5, hi(0x44004800) /* Put "l.jr r9" instruction in r5 */
	l.ori 	r5, r5, lo(0x44004800)
	l.sw 	0x0(r0), r5 	/* Write "l.j r9" to address 0x0 in RAM */	
	l.movhi r5, 0xee00 	/* Put an illegal instruction in r5 */
	l.sw 	0x4(r0), r5   	/* Write illegal instruction to RAM addr 0x4 */
	l.movhi r5, 0x1500 	/* l.nop after illegal instruction */
	l.sw 	0x8(r0), r5   	/* Write nop to RAM addr 0x8 */
	l.mtspr r0,r0,SPR_ICBIR /* Invalidate line 0 of cache */
	/* Jump to 0x4 - illegal opcode instruction */
	l.ori 	r6, r0, 0x4
	OR1K_DELAYED(
	OR1K_INST(l.addi 	r12,r12,1),      /* Increment 2nd exception counter */
	OR1K_INST(l.jalr 	r6) 		/* Jump to address 0x4, land on illegal insn */
 	)
	l.nop 			/* Should return here */	
	l.nop

#ifdef __OR1K_DELAY__
	/* Test in delay slot */
	
	l.movhi r5, 0xee00 	/* Put an illegal instruction in r5 */
	l.sw 	0x4(r0), r5   	/* Write illegal instruction to RAM addr 0x4 */
	l.mtspr r0,r0,SPR_ICBIR /* Invalidate line 0 of cache */	
	l.jalr 	r0 /* Jump to address 0, will be a jump back but with an illegal
	             dslot instruction which will befixed by handler */
	l.addi 	r12,r12,1 	/* Increment 2nd exception counter */
	l.nop 			/* Should return here */
#endif
	
	/* Check 1st and 2nd exception counters are equal */
	l.sfeq	r11,r12		/* Should be equal */
	l.bf 	1f
	l.nop
	l.or 	r3, r12, r12
	l.nop 	2 		/* Report expected exception count */
	l.or 	r3, r11, r11
	l.nop 	2 		/* Report actual exception count */
	l.nop 	1
1:	l.nop
	l.nop
	

_dbus1:
	l.nop
	l.movhi r12, 0 /* Reset exception counters */
	l.movhi r11, 0
	l.ori r2, r0, 0xd /* put 0xd in r2, indicate it's databus test */
	/* Cause access error */
	/* Load word */	
	l.movhi r5, 0xee00 /* Address to cause an error */
	l.lwz r6, 0(r5) 
	l.addi r12, r12, 1 /* Incremement secondary exception counter */
	/* Load half */	
	l.movhi r5, 0xee00 /* Address to cause an error */
	l.lhz r6, 0(r5)
	l.addi r12, r12, 1 /* Incremement secondary exception counter */
	/* Load byte */	
	l.movhi r5, 0xee00 /* Address to cause an error */
	l.lbz r6, 0(r5)
	l.addi r12, r12, 1 /* Incremement secondary exception counter */

	l.movhi	r7, 0		/* clear "exception flag" */
	/* Store word */	
	l.movhi r5, 0xee00 /* Address to cause an error */
	l.sw 0(r5), r6
.L1:	l.sfeqi	r7, 0
	l.bf	.L1		/* wait for "exception flag" */
	 l.nop
	l.addi r12, r12, 1 /* Incremement secondary exception counter */

	l.movhi	r7, 0		/* clear "exception flag" */
	/* Store half */	
	l.movhi r5, 0xee00 /* Address to cause an error */
	l.sh 0(r5), r6
.L2:	l.sfeqi	r7, 0
	l.bf	.L3		/* wait for "exception flag" */
	 l.nop
	l.addi r12, r12, 1 /* Incremement secondary exception counter */

	l.movhi	r7, 0		/* clear "exception flag" */
	/* Store byte */	
	l.movhi r5, 0xee00 /* Address to cause an error */
	l.sb 0(r5), r6
.L3:	l.sfeqi	r7, 0
	l.bf	.L3		/* wait for "exception flag" */
	 l.nop
	l.addi r12, r12, 1 /* Incremement secondary exception counter */	
	l.nop

#ifdef __OR1K_DELAY__
	/* Delay slot tests */
	/* Load word */	
	l.movhi r5, 0xee00 /* Address to cause an error */	
	l.j 1f
	l.lwz r6, 0(r5) /* Data bus error in delay slot */
	l.nop
1:	l.addi r12, r12, 1
	/* Load half */
	l.movhi r5, 0xee00 /* Address to cause an error */	
	l.j 2f
	l.lhz r6, 0(r5) /* Data bus error in delay slot */
	l.nop
2:	l.addi r12, r12, 1	
	/* Load byte */
	l.movhi r5, 0xee00 /* Address to cause an error */	
	l.j 3f
	l.lbz r6, 0(r5) /* Data bus error in delay slot */
	l.nop
3:	l.addi r12, r12, 1	
	l.movhi	r7, 0		/* clear "exception flag" */
	/* Store word */
	l.movhi r5, 0xee00 /* Address to cause an error */	
	l.j 4f
	l.sw 0(r5), r6  /* Data bus error in delay slot */
	l.nop
4:	l.sfeqi	r7, 0
	l.bf	4b		/* wait for "exception flag" */
	 l.nop
	l.addi r12, r12, 1	

	l.movhi	r7, 0		/* clear "exception flag" */
	/* Store half */
	l.movhi r5, 0xee00 /* Address to cause an error */	
	l.j 5f
	l.sh 0(r5), r6  /* Data bus error in delay slot */
	l.nop
5:	l.sfeqi	r7, 0
	l.bf	5b		/* wait for "exception flag" */
	 l.nop
	l.addi r12, r12, 1	

	l.movhi	r7, 0		/* clear "exception flag" */
	/* Store byte */
	l.movhi r5, 0xee00 /* Address to cause an error */	
	l.j 6f
	l.sb 0(r5), r6  /* Data bus error in delay slot */
	l.nop
6:	l.sfeqi	r7, 0
	l.bf	6b		/* wait for "exception flag" */
	 l.nop
	l.addi r12, r12, 1	
#endif
	
/* Check 1st and 2nd exception counters are equal */
	l.sfeq	r11,r12			/* Should be equal */
	l.bf 7f
	l.nop
	l.or r3, r12, r12
	l.nop 2 /* Report expected exception count */
	l.or r3, r11, r11
	l.nop 2 /* Report actual exception count */
	l.nop 1
7:	l.nop

	
	
_ibus1:
	/* TODO: do this it with cache enabled/disabled */	
	l.movhi r12, 0 /* Reset exception counters */
	l.movhi r11, 0
	l.movhi r2, 0x0 /* put 0x0 in r2,indicate it's instruction bus test*/
	/* Cause access error */
	l.movhi r5, 0xee00 /* Address to cause an error */
	l.jalr r5 /* Jump and link to bad address */
	l.nop
	l.addi r12, r12, 1 /* Incremement secondary exception counter */
	/* Check 1st and 2nd exception counters are equal */
	l.sfeq	r11,r12			/* Should be equal */
	l.bf 1f
	l.nop
	l.or r3, r12, r12
	l.nop 2 /* Report expected exception count */
	l.or r3, r11, r11
	l.nop 2 /* Report actual exception count */
	l.nop 1
1:	l.nop
	l.nop	
	
	/* End of tests - report and finish simulation */
	l.movhi	r3,hi(0x8000000d)
	l.ori	r3,r3,lo(0x8000000d)
	l.nop	2

	l.addi r3,r0,0
	l.jal	exit
	l.nop

