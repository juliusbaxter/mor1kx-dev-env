// ----------------------------------------------------------------------------

// Access functions for the ORPSoC Verilator model: implementation

// Copyright (C) 2008  Embecosm Limited <info@embecosm.com>

// Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
// Contributor Julius Baxter <jb@orsoc.se>

// This file is part of the cycle accurate model of the OpenRISC 1000 based
// system-on-chip, ORPSoC, built using Verilator.

// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.

// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
// License for more details.

// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// ----------------------------------------------------------------------------

// $Id: OrpsocMemoryAccess.cpp 303 2009-02-16 11:20:17Z jeremy $

#include "OrpsocMemoryAccess.h"

#include "Vorpsoc_top.h"
#include "Vorpsoc_top_orpsoc_top.h"
// Need RAM instantiation has parameters after module name
// Include for ram_wb
#include "Vorpsoc_top_ram_wb__A20_D20_M800000_MB17.h"
// Include for ram_wb_b3
#include "Vorpsoc_top_ram_wb_b3__pi7.h"

//! Constructor for the ORPSoC access class

//! Initializes the pointers to the various module instances of interest
//! within the Verilator model.

//! @param[in] orpsoc  The SystemC Verilated ORPSoC instance

OrpsocMemoryAccess::OrpsocMemoryAccess(Vorpsoc_top * orpsoc_top)
{

	// Assign main memory accessor objects
	// For old ram_wb: ram_wb_sc_sw = orpsoc_top->v->ram_wb0->ram0;
	//ram_wb_sc_sw = orpsoc_top->v->wb_ram_b3_0;
	wishbone_ram = orpsoc_top->v->ram_wb0->ram_wb_b3_0;

	// Assign arbiter accessor object
	//wb_arbiter = orpsoc_top->v->wb_conbus;

}				// OrpsocMemoryAccess ()

//! Access the Wishbone SRAM memory

//! @return  The value of the 32-bit memory word at addr

uint32_t OrpsocMemoryAccess::get_mem32(uint32_t addr)
{
	return (wishbone_ram->get_mem32) (addr / 4);

}				// get_mem32 ()

//! Access a byte from the Wishbone SRAM memory

//! @return  The value of the memory byte at addr

uint8_t OrpsocMemoryAccess::get_mem8(uint32_t addr)
{

	uint32_t word;
	static uint32_t cached_word;
	static uint32_t cached_word_addr = 0xffffffff;
	int sel = addr & 0x3;	// Remember which byte we want
	addr = addr / 4;
	if (addr != cached_word_addr) {
		cached_word_addr = addr;
		// Convert address to word number here
		word = (wishbone_ram->get_mem8) (addr);
		cached_word = word;
	} else
		word = cached_word;

	switch (sel) {
		/* Big endian word expected */
	case 0:
		return ((word >> 24) & 0xff);
		break;
	case 1:
		return ((word >> 16) & 0xff);
		break;
	case 2:
		return ((word >> 8) & 0xff);
		break;
	case 3:
		return ((word >> 0) & 0xff);
		break;
	default:
		return 0;
	}

}				// get_mem8 ()

//! Write value to the Wishbone SRAM memory

void OrpsocMemoryAccess::set_mem32(uint32_t addr, uint32_t data)
{
	(wishbone_ram->set_mem32) (addr / 4, data);

}				// set_mem32 ()

//! Trigger the $readmemh() system call

void OrpsocMemoryAccess::do_ram_readmemh(void)
{
	(wishbone_ram->do_readmemh) ();

}				// do_ram_readmemh ()

