/*
 * OR1K multiple jump register test
 * 
 */

#include <or1k-asm.h>

/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
	.org 0x100
	l.movhi r0, 0
	l.movhi	r1,hi(start)
	l.ori	r1,r1,lo(start)
	OR1K_DELAYED_NOP(OR1K_INST(l.jr r1))
	l.nop 1
	
	.section .text
start:
	l.ori	r3,r0,4
	l.movhi	r1,hi(one)
	l.ori	r1,r1,lo(one)
	OR1K_DELAYED_NOP(OR1K_INST(l.jr r1))
	l.nop	1
one:
	l.addi	r3,r3,-1
	l.movhi	r1,hi(two)
	l.ori	r1,r1,lo(two)
	OR1K_DELAYED_NOP(OR1K_INST(l.jr r1))
	l.nop	1

two:
	l.addi	r3,r3,-1
	l.movhi	r1,hi(three)
	l.ori	r1,r1,lo(three)
	OR1K_DELAYED_NOP(OR1K_INST(l.jr r1))
	l.nop	1

three:
	l.addi	r3,r3,-1
	l.movhi	r1,hi(four)
	l.ori	r1,r1,lo(four)
	OR1K_DELAYED_NOP(OR1K_INST(l.jr r1))
	l.nop	1

four:
	l.addi	r3,r3,-1
	l.nop	1
