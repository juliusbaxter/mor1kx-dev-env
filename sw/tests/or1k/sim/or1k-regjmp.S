/*

	OR1K jump to reg test

	Stefan Kristiansson, stefan.kristiansson@saunalahti.fi

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
	l.jr    r4
	l.nop

/* =================================================== [ text ] === */
	.section .text

/* =================================================== [ start ] === */

	.global _start
_start:
	/* r16 hold test loop counter */
	l.movhi r16, 0
	// Kick off test
	l.jal   _main
	l.nop



/* =================================================== [ main ] === */

testfunc0:
	l.jr r9
	 l.nop

testfunc1:
	l.nop
	l.jr r9
	 l.nop

testfunc2:
	l.nop
	l.nop
	l.jr r9
	 l.nop

testfunc3:
	l.nop
	l.nop
	l.nop
	l.jr r9
	 l.nop

	.global _main
_main:
	/* Do a serie of really short function calls */
	l.movhi	r1,0
	l.movhi	r4, hi(testfunc0)
	l.ori	r4, r4, lo(testfunc0)
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.movhi	r4, hi(testfunc1)
	l.ori	r4, r4, lo(testfunc1)
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.movhi	r4, hi(testfunc2)
	l.ori	r4, r4, lo(testfunc2)
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.movhi	r4, hi(testfunc3)
	l.ori	r4, r4, lo(testfunc3)
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1
	l.jalr	r4
	 l.addi	r1,r1,1

	/*
	 * Print and check result
	 */
	l.ori	r3, r1, 0
	l.nop	2
	l.sfnei	r1, 16
	l.bf	test_fail
	 l.nop

	/*
	 * Test finished when ran through once without caches enabled
	 * and twice with.
	 */
	l.sfeqi	r16, 2
	l.bf	test_ok
	 l.addi r16, r16, 1

	l.sfeqi r16, 2
	l.bf	_main
	 l.nop

	/* Restart test with cache enabled */
	l.jal 	_cache_init
	 l.nop
	l.j     _main
	 l.nop

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
