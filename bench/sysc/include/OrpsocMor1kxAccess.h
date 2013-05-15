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

// $Id: OrpsocMor1kxAccess.h 303 2009-02-16 11:20:17Z jeremy $

#ifndef ORPSOC_MOR1KX_ACCESS__H
#define ORPSOC_MOR1KX_ACCESS__H

#include <stdint.h>
#include "orpsoc-defines.h"

class Vorpsoc_top;
class Vorpsoc_top_orpsoc_top;

#ifndef MOR1KX_CPU_WRAPPER
#define MOR1KX_CPU_WRAPPER orpsoc_top->v->mor1kx0->mor1kx_cpu
#endif

#ifdef MOR1KX_CPU_prontoespresso
#define mor1kx_pipeline MOR1KX_CPU_WRAPPER ->prontoespresso__DOT__mor1kx_cpu
#endif
#ifdef MOR1KX_CPU_espresso
#define mor1kx_pipeline MOR1KX_CPU_WRAPPER ->espresso__DOT__mor1kx_cpu
#endif
#ifdef MOR1KX_CPU_cappuccino
#define mor1kx_pipeline MOR1KX_CPU_WRAPPER ->cappuccino__DOT__mor1kx_cpu
#endif

//! Access functions to the Verilator model

//! This class encapsulates access to the Verilator model, allowing other
//! Classes to access model state, without needing to be built within the
//! Verilator environment.
class OrpsocMor1kxAccess {
public:

	// Constructor
	OrpsocMor1kxAccess(Vorpsoc_top * orpsoc_top);

	bool getExAdv();
	uint32_t getExInsn();
	uint32_t getExPC();

	// Get a specific GPR from the register file
	uint32_t getGpr(uint32_t regNum);
	void setGpr(uint32_t regNum, uint32_t value);
	//SPR accessessors
	uint32_t getSprSr();
	uint32_t getSprEpcr();
	uint32_t getSprEear();
	uint32_t getSprEsr();
	uint32_t getBranchMispredict();

private:

	Vorpsoc_top *orpsoc_top;
};				// OrpsocMor1kxAccess ()

#endif // ORPSOC_MOR1KX_ACCESS__H
