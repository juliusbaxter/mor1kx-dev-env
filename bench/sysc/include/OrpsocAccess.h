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

#ifndef ORPSOC_ACCESS__H
#define ORPSOC_ACCESS__H

#include <stdint.h>
#include "orpsoc-defines.h"

class Vorpsoc_top;
class Vorpsoc_top_orpsoc_top;

#ifdef OR1200
class Vorpsoc_top_or1200_ctrl;
class Vorpsoc_top_or1200_except;
class Vorpsoc_top_or1200_sprs;
class Vorpsoc_top_or1200_dpram;
#endif
#ifdef MOR1KX
class Vorpsoc_top_mor1kx_cpu;
class Vorpsoc_top_mor1kx_cpu_fourstage;
#endif


// Main memory access class - will change if main memory size or other 
// parameters change
//Old ram_wbclass: class Vorpsoc_top_ram_wb_sc_sw__D20_A19_M800000;
//class Vorpsoc_top_wb_ram_b3__D20_A17_M800000;
class Vorpsoc_top_ram_wb_b3__pi3;
// SoC Arbiter class - will also change if any modifications to bus architecture
//class Vorpsoc_top_wb_conbus_top__pi1;

//! Access functions to the Verilator model

//! This class encapsulates access to the Verilator model, allowing other
//! Classes to access model state, without needing to be built within the
//! Verilator environment.
class OrpsocAccess {
public:

	// Constructor
	OrpsocAccess(Vorpsoc_top * orpsoc_top);
#ifdef OR1200
	// OR1200 Accessor functions
	bool getExFreeze();
	bool getWbFreeze();
	uint32_t getWbInsn();
	uint32_t getIdInsn();
	uint32_t getExInsn();
	uint32_t getWbPC();
	uint32_t getIdPC();
	uint32_t getExPC();
	bool getExceptFlushpipe();
	bool getExDslot();
	uint32_t getExceptType();
#endif
#ifdef MOR1KX
	bool getIdAdv();
	uint32_t getIdInsn();
	bool getExAdv();
	uint32_t getExPC();
#endif
	// Get a specific GPR from the register file
	uint32_t getGpr(uint32_t regNum);
	void setGpr(uint32_t regNum, uint32_t value);
	//SPR accessessors
	uint32_t getSprSr();
	uint32_t getSprEpcr();
	uint32_t getSprEear();
	uint32_t getSprEsr();

	// Wishbone SRAM accessor functions
	uint32_t get_mem32(uint32_t addr);
	uint8_t get_mem8(uint32_t addr);

	void set_mem32(uint32_t addr, uint32_t data);
	// Trigger a $readmemh for the RAM array
	void do_ram_readmemh(void);

private:

#ifdef OR1200
	// Pointers to modules with accessor functions
	Vorpsoc_top_or1200_ctrl * or1200_ctrl;
	Vorpsoc_top_or1200_except *or1200_except;
	Vorpsoc_top_or1200_sprs *or1200_sprs;
	Vorpsoc_top_or1200_dpram *rf_a;
#endif
#ifdef MOR1KX
	Vorpsoc_top_mor1kx_cpu* mor1kx_cpu_wrapper;
	Vorpsoc_top_mor1kx_cpu_fourstage * mor1kx_cpu;
#endif
	/*Vorpsoc_top_ram_wb_sc_sw *//*Vorpsoc_top_ram_wb_sc_sw__D20_A19_M800000 *//*Vorpsoc_top_wb_ram_b3__D20_A17_M800000 *ram_wb_sc_sw; */
	Vorpsoc_top_ram_wb_b3__pi3 *wishbone_ram;
	// Arbiter
	//Vorpsoc_top_wb_conbus_top__pi1 *wb_arbiter;

};				// OrpsocAccess ()

#endif // ORPSOC_ACCESS__H
