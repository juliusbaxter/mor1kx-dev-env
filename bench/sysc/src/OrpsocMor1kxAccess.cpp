// ----------------------------------------------------------------------------

// Access functions for the ORPSoC Verilator model: implementation

// Copyright (C) 2008  Embecosm Limited <info@embecosm.com>
// Copyright (C) 2011  Julius Baxter <juliusbaxter@gmail.com>

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

// $Id$

#include "OrpsocMor1kxAccess.h"

#include "Vorpsoc_top__Syms.h"

#include "Vorpsoc_top.h"
#include "Vorpsoc_top_orpsoc_top.h"

//! Constructor for the ORPSoC access class

//! Initializes the pointers to the various module instances of interest
//! within the Verilator model.

//! @param[in] orpsoc  The SystemC Verilated ORPSoC instance

OrpsocMor1kxAccess::OrpsocMor1kxAccess(Vorpsoc_top * orpsoc_top)
{
	this->orpsoc_top = orpsoc_top;

}				// OrpsocMor1kxAccess ()


//! @return  The value of the decode stage instruction

bool OrpsocMor1kxAccess::getExAdv()
{
  return MOR1KX_CPU_WRAPPER->monitor_execute_advance;
}

uint32_t OrpsocMor1kxAccess::getExInsn()
{
  return MOR1KX_CPU_WRAPPER->monitor_execute_insn;
}

uint32_t OrpsocMor1kxAccess::getExPC()
{
  return MOR1KX_CPU_WRAPPER->monitor_execute_pc;
}

uint32_t OrpsocMor1kxAccess::getSprSr()
{
  return MOR1KX_CPU_WRAPPER->monitor_spr_sr;
}

uint32_t OrpsocMor1kxAccess::getSprEpcr()
{
  return MOR1KX_CPU_WRAPPER->monitor_spr_epcr;
}

uint32_t OrpsocMor1kxAccess::getSprEear()
{
  return MOR1KX_CPU_WRAPPER->monitor_spr_eear;
}

uint32_t OrpsocMor1kxAccess::getSprEsr()
{
  return MOR1KX_CPU_WRAPPER->monitor_spr_esr;
}

uint32_t OrpsocMor1kxAccess::getGpr(uint32_t regNum)
{
  return (mor1kx_pipeline->get_gpr) (regNum);
}

void OrpsocMor1kxAccess::setGpr(uint32_t regNum, uint32_t value)
{
  (mor1kx_pipeline->set_gpr) (regNum, value);
}
