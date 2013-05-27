/*

	OR1K set flag, branch flag test
	Created to bring out corner cases to test branch prediction in
	mor1kx-cappuccino, but the test itself should be generic enough.

	Requires:
	 - delay slot
	 - l.muli instruction

	Stefan Kristiansson, stefan.kristiansson@saunalahti.fi

*/
#include <or1k-asm.h>
#include "spr-defs.h"

/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
        .org 0x100
	l.movhi 	r0, 0
	/* Clear status register */
	l.ori 		r1, r0, SPR_SR_SM
	l.mtspr 	r0, r1, SPR_SR
	/* Clear timer  */
	l.mtspr 	r0, r0, SPR_TTMR

	/* Jump to program initialisation code */
	.global _start
	l.movhi 	r4, hi(_start)
	l.ori 		r4, r4, lo(_start)
	l.jr		r4
	 l.nop

	/* Timer exception, clear interrupt bit, and return */
	.org 0x500
	l.mfspr	r11,r0, SPR_TTMR
	l.movhi	r12, hi(SPR_TTMR_IP)
	l.xor	r11, r11, r12
	l.mtspr	r0, r11, SPR_TTMR
	l.addi	r13,r13,1
	l.rfe

/* =================================================== [ text ] === */
	.section .text

/* =================================================== [ start ] === */

	.global _start
_start:
	/* r16 hold test loop counter */
	l.movhi r16, 0
	// Kick off test
	l.jal		_main
	 l.nop



/* =================================================== [ main ] === */


	.global _main
_main:
	l.movhi r1, 0

	/* backward, taken */
.L1:
	l.sfeqi		r1, 30
	l.bnf		.L1
	 l.addi		r1, r1, 1
	l.addi		r1, r1, 1

	/* report and check result */
	l.ori		r3, r0, 1
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop

	/* backward, taken, flag in delay slot */
	l.movhi		r1, 0
	l.sfne		r0,r0
.L2:
	l.addi		r1, r1, 1
	l.bnf		.L2
	 l.sfeqi	r1, 30
	l.addi		r1, r1, 1

	/* report and check result */
	l.ori		r3, r0, 2
	l.nop		2
	l.sfnei		r1, 32
	l.bf	test_fail
	 l.nop

	/* backward, taken, flag changing value just before bf */
	l.movhi		r1, 0
.L3:
	l.sfeq		r0, r0
	l.sfeqi		r1, 30
	l.bnf		.L3
	 l.addi		r1, r1, 1
	l.addi		r1, r1, 1

	/* report and check result */
	l.ori		r3, r0, 3
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop

	/* backward, taken, change flag in delay slot */
	l.movhi		r1, 0
	l.sfne		r0,r0
.L4:
	l.addi		r1, r1, 1
	l.sfeqi		r1, 30
	l.bnf		.L4
	 l.sfeq		r0, r0
	l.addi		r1, r1, 2

	/* report and check result */
	l.ori		r3, r0, 4
	l.nop		2
	l.sfnei		r1, 32
	l.bf	test_fail
	 l.nop

	/* forward, not taken */
	l.movhi		r1, 0
.L5:
	l.sfeqi		r1, 30
	l.bf		.Lexit5
	 l.addi		r1, r1, 1
	l.j		.L5
	 l.addi		r1, r1, 1

.Lexit5:
	l.addi		r1, r1, 1

	/* report and check result */
	l.ori		r3, r0, 5
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop

	/* forward, taken */
	l.movhi		r1, 0
.L6:
	l.sfeqi		r1, 30
	l.bnf		.L6_0
	 l.addi		r1, r1, 1
	l.j		.Lexit6
	 l.addi		r1, r1, 1

.L6_0:
	l.j		.L6
	 l.addi		r1, r1, 1

.Lexit6:

	/* report and check result */
	l.ori		r3, r0, 6
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop

	/* forward, taken */
	l.movhi		r1, 0
	l.movhi		r2, 0
.L7:
	l.sfeqi		r1, 31
	l.bnf		.L7_0
	 l.addi		r1, r1, 1
	l.j		.Lexit7
	 l.addi		r2, r2, 1

.L7_0:
	l.j		.L7
	 l.addi		r2, r2, 1

.Lexit7:

	/* report and check result */
	l.ori		r3, r0, 7
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop
	l.sfnei		r2, 32
	l.bf		test_fail
	 l.nop

	/* forward, not taken, with sf in delay slot*/
	l.movhi		r1, 0
	l.movhi		r2, 0
	l.sfne		r0, r0
.L8:
	l.addi		r1, r1, 1
	l.bf		.Lexit8
	 l.sfeqi	r1, 30
	l.j		.L8
	 l.addi		r2, r2, 1

.Lexit8:
	l.addi		r1, r1, 1
	l.addi		r2, r2, 2

	/* report and check result */
	l.ori		r3, r0, 8
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop
	l.sfnei		r2, 32
	l.bf		test_fail
	 l.nop

	/* forward, taken, with side effect after delay slot */
	l.movhi		r1, 0
	l.movhi		r2, 0
.L9:
	l.sfeqi		r1, 31
	l.bnf		.L9_0
	 l.addi		r1, r1, 1
	l.addi		r2, r2, 1
	l.j		.Lexit9
	 l.nop

.L9_0:
	l.j		.L9
	 l.addi		r2, r2, 1

.Lexit9:
	/* report and check result */
	l.ori		r3, r0, 9
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop
	l.sfnei		r2, 32
	l.bf		test_fail
	 l.nop

	/* backward, not taken */
	l.movhi		r1, 0
	l.movhi		r2, 0
	l.j		.L10_0
	 l.nop
.L10:
	l.j		.Lexit10
	 l.nop
.L10_0:
	l.sfeqi		r1, 31
	l.bf		.L10
	 l.addi		r1, r1, 1
	l.j		.L10_0
	 l.addi		r2, r2, 1

.Lexit10:
	l.addi		r2, r2, 1

	/* report and check result */
	l.ori		r3, r0, 10
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop
	l.sfnei		r2, 32
	l.bf		test_fail
	 l.nop

	/* backward, not taken, flag in delay slot */
	l.movhi		r1, 0
	l.movhi		r2, 0
	l.j		.L11_0
	 l.sfne		r0,r0
.L11:
	l.j		.Lexit11
	 l.nop
.L11_0:
	l.addi		r1, r1, 1
	l.bf		.L11
	 l.sfeqi	r1, 31
	l.addi		r2, r2, 1
	l.j		.L11_0
	 l.nop

.Lexit11:
	l.addi		r2, r2, 1

	/* report and check result */
	l.ori		r3, r0, 11
	l.nop		2
	l.sfnei		r1, 32
	l.bf	test_fail
	 l.nop
	l.sfnei		r2, 32
	l.bf		test_fail
	 l.nop


	/* backward, not taken, flag changing value just before bf */
	l.movhi		r1, 0
	l.movhi		r2, 0
	l.j		.L12_0
	 l.nop
.L12:
	l.j		.Lexit12
	 l.nop
.L12_0:
	l.sfeq		r0, r0
	l.sfeqi		r1, 31
	l.bf		.L12
	 l.addi		r1, r1, 1
	l.addi		r2, r2, 1
	l.j		.L12_0
	 l.nop

.Lexit12:
	l.addi		r2, r2, 1

	/* report and check result */
	l.ori		r3, r0, 12
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop
	l.sfnei		r2, 32
	l.bf		test_fail
	 l.nop

	/* backward, not taken, change flag in delay slot */
	l.movhi		r1, 0
	l.movhi		r2, 0
	l.j		.L13_0
	 l.sfne		r0,r0
.L13:
	l.j		.Lexit13
	 l.nop
.L13_0:
	l.addi		r1, r1, 1
	l.sfeqi		r1, 32
	l.bf		.L13
	 l.sfne		r0, r0
	l.addi		r2, r2, 1
	l.j		.L13_0
	 l.nop

.Lexit13:
	l.addi		r2, r2, 1

	/* report and check result */
	l.ori		r3, r0, 13
	l.nop		2
	l.sfnei		r1, 32
	l.bf		test_fail
	 l.nop
	l.sfnei		r2, 32
	l.bf		test_fail
	 l.nop

	/*
	 * Test with backwards and forward branches, taken and not taken with
	 * muls to induce some stalling to the pipeline
	 */
	l.ori		r3, r0, 14
	l.nop		2
	l.movhi		r1, 0
	l.movhi		r2, 0
	l.ori		r5, r0, 4
.L14_0:
	l.sfeq		r0,r0
	l.bf		.L14_1 /* forward, taken */
	 l.muli		r5, r5, 2
	l.addi 		r1, r1, 1
.L14_1:
	l.sfnei		r1, 0
	l.bf		test_fail
	 l.nop
	l.sfnei		r5, 8
	l.bf		test_fail
	 l.nop
	l.j		.L14_3

.L14_2:
	l.sfnei		r1, 0
	l.bf		test_fail
	 l.nop
	l.sfnei		r5, 16
	l.bf		test_fail
	 l.nop
	l.j		.L14_4

.L14_3:
	l.sfeq		r0,r0
	l.bf		.L14_2 /* backward, taken */
	 l.muli		r5, r5, 2
	l.addi 		r1, r1, 1

.L14_4:
	l.sfeq		r0,r0
	l.bnf		.L14_5 /* forward, not taken */
	 l.muli		r5, r5, 2
	l.addi 		r1, r1, 1

.L14_5:
	l.sfnei		r1, 1
	l.bf		test_fail
	 l.nop
	l.sfnei		r5, 32
	l.bf		test_fail
	 l.nop

.L14_6:
	l.sfeq		r0,r0
	l.bnf		.L14_6 /* backward, not taken */
	 l.muli		r5, r5, 2
	l.addi 		r1, r1, 1

	l.sfnei		r1, 2
	l.bf		test_fail
	 l.nop
	l.sfnei		r5, 64
	l.bf		test_fail
	 l.nop

	/* branch over jump test */
	l.ori		r3, r0, 15
	l.nop		2
	l.movhi		r1, 0
	l.movhi		r2, 0

	l.sfeq		r0,r0
	l.bf		.L15_0 /* forward, taken */
	 l.addi		r1, r1, 1
	l.j		test_fail
	 l.nop
.L15_0:

	l.sfnei		r1, 1
	l.bf		test_fail
	 l.nop

	l.sfne		r0,r0
	l.bf		.L15_1 /* forward, not taken */
	 l.addi		r1, r1, 1
	l.j		.L15_2
	 l.nop
.L15_1:
	l.j		test_fail
	 l.nop
.L15_2:

	l.sfnei		r1, 2
	l.bf		test_fail
	 l.nop

	l.j		.L15_4
	 l.nop
.L15_3:
	l.j		.L15_5
	 l.nop

.L15_4:
	l.sfeq		r0,r0
	l.bf		.L15_3 /* backward, taken */
	 l.addi		r1, r1, 1
	l.j		test_fail
	 l.nop

.L15_5:
	l.sfnei		r1, 3
	l.bf		test_fail
	 l.nop

	l.sfne		r0,r0
	l.bf		.L15_5 /* backward, not taken */
	 l.addi		r1, r1, 1
	l.j		.L15_6
	 l.nop
	l.j		test_fail
	 l.nop
.L15_6:

	l.sfnei		r1, 4
	l.bf		test_fail
	 l.nop

	l.j		.L15_8
	 l.nop
.L15_7:
	l.j		.L15_9
	 l.nop

.L15_8:
	l.sw		0(r0), r0
	l.lwz		r3, 0(r0)
	l.sfeq		r3, r0
	l.bf		.L15_7 /* backward, taken */
	 l.addi		r1, r1, 1
	l.j		test_fail
	 l.nop

.L15_9:
	l.sfnei		r1, 5
	l.bf		test_fail
	 l.nop

	/* branch to jal, with counter in delay slot */
	l.ori		r3, r0, 16
	l.nop		2
	l.ori		r1, r1, 32
	l.movhi		r2, 0
	l.j		.L16_1
	 l.nop
.L16_0:
	l.jr		r9
	 l.lwz		r3, 0(r0)
.L16_1:
	l.jal		.L16_0
	 l.addi		r1, r1, -1
	l.sfeqi		r1, 0
	l.bnf		.L16_1 /* backward, taken */
	 l.nop

	l.sfnei		r1, 0
	l.bf		test_fail
	 l.nop

	/*
	 * Test finished when ran through once without caches enabled
	 * and twice with.
	 */
	l.sfeqi		r16, 2
	l.bf		test_ok
	 l.addi		r16, r16, 1

	l.sfeqi		r16, 2
	l.bf		_main
	 l.nop

	/* Restart test with cache enabled */
	l.jal		_cache_init
	 l.nop
	l.j		_main
	 l.nop


test_fail:
	l.movhi		r3,0xbaaa
	l.ori		r3,r3,0xaaad
	l.nop		0x1

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
	/* interrupt every 30 cycles */
	l.ori	r6, r0, 30

	/* load timer */
	l.or	r5,r4,r6 /* value we'll interrupt on */
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR
	l.mtspr r0,r5,SPR_TTMR		# set TTMR
	l.mtspr r0,r0,SPR_TTCR 		# set TTCR

	/* clear r13, tick interrupt counter */
	l.movhi	r13, 0

	l.j	_start
	l.nop