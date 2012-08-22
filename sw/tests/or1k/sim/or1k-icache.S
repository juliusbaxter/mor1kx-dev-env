/*
 * OR1K instruction cache test
 *
 * (C) Copyright 2011, Stefan Kristiansson <stefan.kristiansson@saunalahti.fi>
 */

#include "spr-defs.h"
#include "board.h"

#define ENABLE_IC()			;\
	l.mfspr	r31, r0, SPR_SR		;\
	l.ori	r31, r31, SPR_SR_ICE	;\
	l.mtspr	r0, r31, SPR_SR

#define DISABLE_IC()			;\
	l.mfspr	r31, r0, SPR_SR		;\
	l.addi	r30, r0, -1		;\
	l.xori	r30, r30, SPR_SR_ICE	;\
	l.and	r30, r30, r31		;\
	l.mtspr	r0, r30, SPR_SR

#define ENABLE_DC()			;\
	l.mfspr	r31, r0, SPR_SR		;\
	l.ori	r31, r31, SPR_SR_DCE	;\
	l.mtspr	r0, r31, SPR_SR

#define DISABLE_DC()			;\
	l.mfspr	r31, r0, SPR_SR		;\
	l.addi	r30, r0, -1		;\
	l.xori	r30, r30, SPR_SR_DCE	;\
	l.and	r30, r30, r31		;\
	l.mtspr	r0, r30, SPR_SR

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
	DISABLE_DC()
	/* first jump into the unmodified test area */
	l.jal	_test_area
	 l.nop

	/* copy test1 into the test area */
	l.movhi	r3, hi(_test1)
	l.ori	r3, r3, lo(_test1)
	l.movhi	r4, hi(_test1_end)
	l.ori	r4, r4, lo(_test1_end)
	l.movhi	r5, hi(_test_area)
	l.ori	r5, r5, lo(_test_area)
	l.jal	_copy_test
	 l.nop
	/* test area should still be in cache */
	l.jal	_test_area
	 l.nop

	DISABLE_IC()
	l.movhi	r3, hi(_test2)
	l.ori	r3, r3, lo(_test2)
	l.movhi	r4, hi(_test2_end)
	l.ori	r4, r4, lo(_test2_end)
	l.movhi	r5, hi(_test_area)
	l.ori	r5, r5, lo(_test_area)
	l.jal	_copy_test
	 l.nop
	/* with cache turned off we should reach test2 */
	l.jal	_test_area
	 l.nop
	ENABLE_IC()
	/* the original _test_area should still be in cache */
	l.jal	_test_area
	 l.nop

	/* invalidate _test_area */

	l.movhi	r3, 0
	l.jal	exit
	 l.nop

/*
 * copies from the area pointed by r3->r4 to the place where r5 points to
 * clobbers r6
 */
_copy_test:
	l.lwz	r6,0(r3)
	l.sw	0(r5),r6
	l.addi	r3,r3,4
	l.sfltu	r3,r4
	l.bf	_copy_test
	 l.addi	r5,r5,4
	l.jr	r9
	 l.nop

_test1:
	l.ori	r3,r0,0x1
	l.nop	2
	l.jr	r9
	 l.nop
_test1_end:

_test2:
	l.ori	r3,r0,0x2
	l.nop	2
	l.jr	r9
	 l.nop
_test2_end:

	/* area to which code snippets with same size as itself are written */
_test_area:
	l.ori	r3,r0,0x7e57
	l.nop	2
	l.jr	r9
	 l.nop
_test_area_end: