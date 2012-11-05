/*
 * OR1K conditional move instruction test
 *
 * Stefan Kristiansson <stefan.kristiansson@saunalahti.fi>
 */
#include <or1k-asm.h>
/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
	.org 0x100
	l.andi	r0, r0, 0
	l.ori	r4, r0, 1
	l.ori	r5, r0, 2

	// test true, r6 should contain r4 = 1
	l.sfgtu	r5, r4
	l.cmov	r6, r4, r5
	l.sfnei	r6, 1
	OR1K_DELAYED_NOP(OR1K_INST(l.bf	fail))

	// test false, r6 should contain r5 = 2
	l.sfeq	r4, r5
	l.cmov	r6, r4, r5
	l.sfnei	r6, 2
	OR1K_DELAYED_NOP(OR1K_INST(l.bf	fail))	

	// test true with dest = src, r6 should contain r6 = 1
	l.or	r6, r0, r4
	l.sfgtu	r5, r6
	l.cmov	r6, r6, r5
	l.sfnei	r6, 1
	OR1K_DELAYED_NOP(OR1K_INST(l.bf	fail))

	// test false with dest = src, r6 should contain r6 = 2
	l.or	r6, r0, r5
	l.sfeq	r4, r6
	l.cmov	r6, r4, r6
	l.sfnei	r6, 2
	OR1K_DELAYED_NOP(OR1K_INST(l.bf	fail))

	l.movhi	r3, 0x8000
	l.ori	r3, r3, 0x000d
	l.nop	2
	l.movhi	r3, 0x6000
	l.ori	r3, r3, 0x000d
	l.nop	2
	l.movhi	r3, 0
	l.nop 	1

fail:
	l.movhi	r3, 0xbaaa
	l.ori	r3, r3, 0xaaad
	l.nop	1

	.org	0x700
	OR1K_DELAYED_NOP(OR1K_INST(l.j	fail))