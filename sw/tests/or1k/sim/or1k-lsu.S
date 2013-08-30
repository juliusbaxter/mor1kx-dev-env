/*

	OR1K load/store test

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

	/* Timer exception, clear interrupt bit, and return */
	.org 0x500
	l.mfspr	r21,r0, SPR_TTMR
	l.movhi	r22, hi(SPR_TTMR_IP)
	l.xor	r21, r21, r22
	l.mtspr	r0, r21, SPR_TTMR
	l.addi	r23,r23,1
	l.rfe

	// Alignment error handler.
	// Clobbers r3,r4, increments r1
	// Steps over exception-causing instruction
	.org 0x600

	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get PC of bad jump instruction */
	l.nop 	0x2
	l.addi	r3,r3,4 	/* Step over error instruction */
	l.mtspr	r0,r3,SPR_EPCR_BASE
	l.addi	r1,r1,1		/* Increment exception counter */
	l.or	r3,r1,r0	/* Move counter to r3 to report */
	l.nop 	0x2
	l.rfe


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

	.global _main
_main:
	/* test store immediately followed by load */
	l.movhi	r3, 0
	l.movhi	r4, 0xdead
	l.ori	r4,r4,0xbeef
	l.sw	0x2000(r0), r4
	l.lwz	r3, 0x2000(r0)

	/* Report result */
	l.nop 0x2

	l.sfne	r3,r4
	l.bf	test_fail
	 l.nop

	/* test load followed by multi cycle alu instruction */
	l.movhi	r3, 0
	l.movhi	r4, 0xdead
	l.ori	r4,r4,0xbeef
	l.sw	0x2000(r0), r4
	/* 'Flush' pipeline to prevent forwarding of registers */
	l.nop
	l.nop
	l.nop
	l.nop
	l.nop

	l.lwz	r3, 0x2000(r0)
	l.divu	r3, r3, r4

	/* Report result */
	l.nop 0x2

	l.sfnei	r3, 1
	l.bf	test_fail
	 l.nop

	/*
	 * Test a series of stores followed by a series of loads.
	 * Imitating typical prologue/epilogue stack operations
	 */
	l.ori	r1, r0, 0x2000
	l.ori	r2, r0, 2
	l.ori	r3, r0, 3
	l.ori	r4, r0, 4
	l.ori	r5, r0, 5
	l.ori	r6, r0, 6
	l.ori	r7, r0, 7
	l.ori	r8, r0, 8
	l.ori	r9, r0, 9
	l.ori	r10, r0, 10
	l.ori	r11, r0, 11
	l.ori	r12, r0, 12
	l.ori	r13, r0, 13
	l.ori	r14, r0, 14
	l.sw	0(r1), r2
	l.sw	4(r1), r3
	l.sw	8(r1), r4
	l.sw	12(r1), r5
	l.sw	16(r1), r6
	l.sw	20(r1), r7
	l.sw	24(r1), r8
	l.sw	28(r1), r9
	l.sw	32(r1), r10
	l.sw	36(r1), r11
	l.sw	40(r1), r12
	l.sw	44(r1), r13
	l.sw	48(r1), r14
	l.movhi	r2, 0
	l.movhi	r3, 0
	l.movhi	r4, 0
	l.movhi	r5, 0
	l.movhi	r6, 0
	l.movhi	r7, 0
	l.movhi	r8, 0
	l.movhi	r9, 0
	l.movhi	r10, 0
	l.movhi	r11, 0
	l.movhi	r12, 0
	l.movhi	r13, 0
	l.movhi	r14, 0
	l.lwz	r2, 0(r1)
	l.lwz	r3, 4(r1)
	l.lwz	r4, 8(r1)
	l.lwz	r5, 12(r1)
	l.lwz	r6, 16(r1)
	l.lwz	r7, 20(r1)
	l.lwz	r8, 24(r1)
	l.lwz	r9, 28(r1)
	l.lwz	r10, 32(r1)
	l.lwz	r11, 36(r1)
	l.lwz	r12, 40(r1)
	l.lwz	r13, 44(r1)
	l.lwz	r14, 48(r1)

	/* check and report results */
	l.ori 	r15, r3, 0
	l.ori	r3, r2, 0
	l.nop	2
	l.ori 	r3, r15, 0
	l.sfnei	r2, 2
	l.bf	test_fail
	 l.nop

	l.nop	2
	l.sfnei	r3, 3
	l.bf	test_fail
	 l.nop

	l.ori	r3, r4, 0
	l.nop	2
	l.sfnei	r4, 4
	l.bf	test_fail
	 l.nop

	l.ori	r3, r5, 0
	l.nop	2
	l.sfnei	r5, 5
	l.bf	test_fail
	 l.nop

	l.ori	r3, r6, 0
	l.nop	2
	l.sfnei	r6, 6
	l.bf	test_fail
	 l.nop

	l.ori	r3, r7, 0
	l.nop	2
	l.sfnei	r7, 7
	l.bf	test_fail
	 l.nop

	l.ori	r3, r8, 0
	l.nop	2
	l.sfnei	r8, 8
	l.bf	test_fail
	 l.nop

	l.ori	r3, r9, 0
	l.nop	2
	l.sfnei	r9, 9
	l.bf	test_fail
	 l.nop

	l.ori	r3, r10, 0
	l.nop	2
	l.sfnei	r10, 10
	l.bf	test_fail
	 l.nop

	l.ori	r3, r11, 0
	l.nop	2
	l.sfnei	r11, 11
	l.bf	test_fail
	 l.nop

	l.ori	r3, r12, 0
	l.nop	2
	l.sfnei	r12, 12
	l.bf	test_fail
	 l.nop

	l.ori	r3, r13, 0
	l.nop	2
	l.sfnei	r13, 13
	l.bf	test_fail
	 l.nop

	l.ori	r3, r14, 0
	l.nop	2
	l.sfnei	r14, 14
	l.bf	test_fail
	 l.nop


	/*
	 * Test byte store and load "bursts"
	 */
	l.ori	r1, r0, 0x2000
	l.sw	0(r1), r0
	l.sw	4(r1), r0
	l.sw	8(r1), r0
	l.sw	12(r1), r0
	l.sw	16(r1), r0
	l.sw	20(r1), r0
	l.sw	24(r1), r0

	l.ori	r2, r0, 2
	l.ori	r3, r0, 3
	l.ori	r4, r0, 4
	l.ori	r5, r0, 5
	l.ori	r6, r0, 6
	l.ori	r7, r0, 7
	l.ori	r8, r0, 8
	l.ori	r9, r0, 9
	l.sb	0(r1), r2
	l.sb	1(r1), r3
	l.sb	2(r1), r4
	l.sb	3(r1), r5
	l.sb	4(r1), r6
	l.sb	5(r1), r7
	l.sb	6(r1), r8
	l.sb	7(r1), r9

	l.movhi	r2, 0
	l.movhi	r3, 0
	l.movhi	r4, 0
	l.movhi	r5, 0
	l.movhi	r6, 0
	l.movhi	r7, 0
	l.movhi	r8, 0
	l.movhi	r9, 0

	l.lbz	r2, 0(r1)
	l.lbz	r3, 1(r1)
	l.lbz	r4, 2(r1)
	l.lbz	r5, 3(r1)
	l.lbz	r6, 4(r1)
	l.lbz	r7, 5(r1)
	l.lbz	r8, 6(r1)
	l.lbz	r9, 7(r1)

	l.ori 	r15, r3, 0
	l.ori	r3, r2, 0
	l.nop	2
	l.ori 	r3, r15, 0
	l.sfnei	r2, 2
	l.bf	test_fail
	 l.nop

	l.nop	2
	l.sfnei	r3, 3
	l.bf	test_fail
	 l.nop

	l.ori	r3, r4, 0
	l.nop	2
	l.sfnei	r4, 4
	l.bf	test_fail
	 l.nop

	l.ori	r3, r5, 0
	l.nop	2
	l.sfnei	r5, 5
	l.bf	test_fail
	 l.nop

	l.ori	r3, r6, 0
	l.nop	2
	l.sfnei	r6, 6
	l.bf	test_fail
	 l.nop

	l.ori	r3, r7, 0
	l.nop	2
	l.sfnei	r7, 7
	l.bf	test_fail
	 l.nop

	l.ori	r3, r8, 0
	l.nop	2
	l.sfnei	r8, 8
	l.bf	test_fail
	 l.nop

	l.ori	r3, r9, 0
	l.nop	2
	l.sfnei	r9, 9
	l.bf	test_fail
	 l.nop

	/*
	 * Test halfword store and load "bursts"
	 */
	l.ori	r1, r0, 0x2000
	l.sw	0(r1), r0
	l.sw	4(r1), r0
	l.sw	8(r1), r0
	l.sw	12(r1), r0
	l.sw	16(r1), r0
	l.sw	20(r1), r0
	l.sw	24(r1), r0

	l.ori	r2, r0, 2
	l.ori	r3, r0, 3
	l.ori	r4, r0, 4
	l.ori	r5, r0, 5
	l.ori	r6, r0, 6
	l.ori	r7, r0, 7
	l.ori	r8, r0, 8
	l.ori	r9, r0, 9
	l.sh	0(r1), r2
	l.sh	2(r1), r3
	l.sh	4(r1), r4
	l.sh	6(r1), r5
	l.sh	8(r1), r6
	l.sh	10(r1), r7
	l.sh	12(r1), r8
	l.sh	14(r1), r9

	l.movhi	r2, 0
	l.movhi	r3, 0
	l.movhi	r4, 0
	l.movhi	r5, 0
	l.movhi	r6, 0
	l.movhi	r7, 0
	l.movhi	r8, 0
	l.movhi	r9, 0

	l.lhz	r2, 0(r1)
	l.lhz	r3, 2(r1)
	l.lhz	r4, 4(r1)
	l.lhz	r5, 6(r1)
	l.lhz	r6, 8(r1)
	l.lhz	r7, 10(r1)
	l.lhz	r8, 12(r1)
	l.lhz	r9, 14(r1)

	l.ori 	r15, r3, 0
	l.ori	r3, r2, 0
	l.nop	2
	l.ori 	r3, r15, 0
	l.sfnei	r2, 2
	l.bf	test_fail
	 l.nop

	l.nop	2
	l.sfnei	r3, 3
	l.bf	test_fail
	 l.nop

	l.ori	r3, r4, 0
	l.nop	2
	l.sfnei	r4, 4
	l.bf	test_fail
	 l.nop

	l.ori	r3, r5, 0
	l.nop	2
	l.sfnei	r5, 5
	l.bf	test_fail
	 l.nop

	l.ori	r3, r6, 0
	l.nop	2
	l.sfnei	r6, 6
	l.bf	test_fail
	 l.nop

	l.ori	r3, r7, 0
	l.nop	2
	l.sfnei	r7, 7
	l.bf	test_fail
	 l.nop

	l.ori	r3, r8, 0
	l.nop	2
	l.sfnei	r8, 8
	l.bf	test_fail
	 l.nop

	l.ori	r3, r9, 0
	l.nop	2
	l.sfnei	r9, 9
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

	/* clear r23, tick interrupt counter */
	l.movhi	r23, 0

	l.j	_start
	l.nop