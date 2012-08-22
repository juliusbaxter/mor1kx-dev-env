/*

	OR1K shift operation test
	
	Check basic functionality.

	Julius Baxter, juliusbaxter@gmail.com

	
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


	l.ori	r1,r0,1
	l.ori	r2,r0,3
	l.sll	r3,r1,r2

	l.sfnei r3, 8
	l.bf	fail
	l.nop

	l.slli	r3,r1,3

	l.sfnei r3, 8
	l.bf	fail
	l.nop

	l.ori	r1,r0,512
	l.ori	r2,r0,4
	l.srl	r3,r1,r2

	l.sfnei r3, 32
	l.bf	fail
	l.nop

	l.srli	r3,r1,4

	l.sfnei r3, 32
	l.bf	fail
	l.nop

	l.ori	r1,r0,512
	l.ori	r2,r0,4
	l.srl	r3,r1,r2
	l.sll	r4,r1,r2
	l.srli	r5,r1,1

	l.sfnei r3, 32
	l.bf	fail
	l.nop
	l.sfnei	r4,0x2000
	l.bf	fail
	l.nop
	l.sfnei	r5,0x100
	l.bf	fail
	l.nop

	l.movhi	r1,0x8000
	l.srai	r2,r1,8

	l.movhi	r3,0xff80
	l.sfne	r3,r2
	l.bf	fail
	l.nop

	
	
	l.movhi	r3, 0x6000
	l.ori	r3,r3,0x000d
	l.nop 	1



fail:
	l.movhi	r3, 0xbaaa
	l.ori	r3, r3, 0xaaad
	l.nop	0x1