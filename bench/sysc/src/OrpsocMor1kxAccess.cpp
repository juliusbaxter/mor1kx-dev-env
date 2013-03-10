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

#include "Vorpsoc_top.h"
#include "Vorpsoc_top_orpsoc_top.h"

//#include "Vorpsoc_top_mor1kx__FG454e41424c4544.h"
#include "Vorpsoc_top_mor1kx__pi1.h"

#ifdef MOR1KX_CPU_prontoespresso
#include "Vorpsoc_top_mor1kx_cpu__pi3.h"
#include "Vorpsoc_top_mor1kx_cpu_prontoespresso__pi4.h"
#endif
#ifdef MOR1KX_CPU_espresso
#include "Vorpsoc_top_mor1kx_cpu__pi3.h"
#include "Vorpsoc_top_mor1kx_cpu_espresso__pi4.h"
#endif
#ifdef MOR1KX_CPU_cappuccino
#include "Vorpsoc_top_mor1kx_cpu__pi5.h"
#include "Vorpsoc_top_mor1kx_cpu_cappucino__pi8.h"
#endif

//! Constructor for the ORPSoC access class

//! Initializes the pointers to the various module instances of interest
//! within the Verilator model.

//! @param[in] orpsoc  The SystemC Verilated ORPSoC instance

OrpsocMor1kxAccess::OrpsocMor1kxAccess(Vorpsoc_top * orpsoc_top)
{
	mor1kx_cpu_wrapper = orpsoc_top->v->mor1kx0->mor1kx_cpu;
#ifdef MOR1KX_CPU_prontoespresso
	mor1kx_cpu = orpsoc_top->v->mor1kx0->mor1kx_cpu->prontoespresso__DOT__mor1kx_cpu;
#endif
#ifdef MOR1KX_CPU_espresso
	mor1kx_cpu = orpsoc_top->v->mor1kx0->mor1kx_cpu->espresso__DOT__mor1kx_cpu;
#endif
#ifdef MOR1KX_CPU_cappuccino
	mor1kx_cpu = orpsoc_top->v->mor1kx0->mor1kx_cpu->cappuccino__DOT__mor1kx_cpu;
#endif


}				// OrpsocMor1kxAccess ()


//! @return  The value of the decode stage instruction

bool OrpsocMor1kxAccess::getExAdv()
{
  return mor1kx_cpu_wrapper->monitor_execute_advance;
}

uint32_t OrpsocMor1kxAccess::getExInsn()
{
  return mor1kx_cpu_wrapper->monitor_execute_insn;
}

uint32_t OrpsocMor1kxAccess::getExPC()
{
  return mor1kx_cpu_wrapper->monitor_execute_pc;
}

uint32_t OrpsocMor1kxAccess::getSprSr()
{
  return mor1kx_cpu_wrapper->monitor_spr_sr;
}

uint32_t OrpsocMor1kxAccess::getSprEpcr()
{
  return mor1kx_cpu_wrapper->monitor_spr_epcr;
}

uint32_t OrpsocMor1kxAccess::getSprEear()
{
  return mor1kx_cpu_wrapper->monitor_spr_eear;
}

uint32_t OrpsocMor1kxAccess::getSprEsr()
{
  return mor1kx_cpu_wrapper->monitor_spr_esr;
}

uint32_t OrpsocMor1kxAccess::getGpr(uint32_t regNum)
{
  return (mor1kx_cpu->get_gpr) (regNum);
}

void OrpsocMor1kxAccess::setGpr(uint32_t regNum, uint32_t value)
{
  (mor1kx_cpu->set_gpr) (regNum, value);
}

