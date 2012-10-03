/*
 * OR1K multiple jump test
 * 
 */

#include <or1k-asm.h>

/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
	.org 0x100
	l.movhi r0, 0
	OR1K_DELAYED_NOP(OR1K_INST(l.j   start))

	.section .text
start:
	l.ori	r3,r0,4
	OR1K_DELAYED_NOP(OR1K_INST(l.j   one))
	l.nop	1
one:
	l.addi	r3,r3,-1
	OR1K_DELAYED_NOP(OR1K_INST(l.j   two))
	l.nop	1

two:
	l.addi	r3,r3,-1
	OR1K_DELAYED_NOP(OR1K_INST(l.j   three))
	l.nop	1

three:
	l.addi	r3,r3,-1
	OR1K_DELAYED_NOP(OR1K_INST(l.j   four))
	l.nop	1

four:
	l.addi	r3,r3,-1
	l.nop	1
