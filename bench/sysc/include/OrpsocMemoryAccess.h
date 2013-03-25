// ----------------------------------------------------------------------------

// Access functions for the ORPSoC Verilator model: definition

// Copyright (C) 2008  Embecosm Limited <info@embecosm.com>

// Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

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

// $Id: OrpsocAccess.h 303 2009-02-16 11:20:17Z jeremy $

#ifndef ORPSOC_MEMORY_ACCESS__H
#define ORPSOC_MEMORY_ACCESS__H

#include <stdint.h>
#include "orpsoc-defines.h"

#define wishbone_ram orpsoc_top->v->ram_wb0->ram_wb_b3_0

class Vorpsoc_top;
class Vorpsoc_top_orpsoc_top;

//! Access functions to the Verilator model

//! This class encapsulates access to the Verilator model, allowing other
//! Classes to access model state, without needing to be built within the
//! Verilator environment.
class OrpsocMemoryAccess {
public:

	// Constructor
	OrpsocMemoryAccess(Vorpsoc_top * orpsoc_top);


	// Wishbone SRAM accessor functions
	uint32_t get_mem32(uint32_t addr);
	uint8_t get_mem8(uint32_t addr);

	void set_mem32(uint32_t addr, uint32_t data);
	// Trigger a $readmemh for the RAM array
	void do_ram_readmemh(void);

private:

	Vorpsoc_top *orpsoc_top;
};				// OrpsocMemoryAccess ()

#endif // ORPSOC_MEMORY_ACCESS__H
