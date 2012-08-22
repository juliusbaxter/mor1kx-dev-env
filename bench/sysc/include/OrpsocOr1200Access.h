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

#ifndef ORPSOC_OR1200_ACCESS__H
#define ORPSOC_OR1200_ACCESS__H

#include <stdint.h>
#include "orpsoc-defines.h"

class Vorpsoc_top;
class Vorpsoc_top_orpsoc_top;


class Vorpsoc_top_or1200_ctrl;
class Vorpsoc_top_or1200_except;
class Vorpsoc_top_or1200_sprs;
class Vorpsoc_top_or1200_dpram;

//! Access functions to the Verilator model

//! This class encapsulates access to the Verilator model, allowing other
//! Classes to access model state, without needing to be built within the
//! Verilator environment.
class OrpsocOr1200Access {
public:

	// Constructor
	OrpsocOr1200Access(Vorpsoc_top * orpsoc_top);

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

	// Get a specific GPR from the register file
	uint32_t getGpr(uint32_t regNum);
	void setGpr(uint32_t regNum, uint32_t value);
	//SPR accessessors
	uint32_t getSprSr();
	uint32_t getSprEpcr();
	uint32_t getSprEear();
	uint32_t getSprEsr();

private:
	// Pointers to modules with accessor functions
	Vorpsoc_top_or1200_ctrl * or1200_ctrl;
	Vorpsoc_top_or1200_except *or1200_except;
	Vorpsoc_top_or1200_sprs *or1200_sprs;
	Vorpsoc_top_or1200_dpram *rf_a;
};				// OrpsocOr1200Access ()

#endif // ORPSOC_OR1200_ACCESS__H
