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

// $Id: OrpsocOr1200Access.cpp 303 2009-02-16 11:20:17Z jeremy $

#include "OrpsocOr1200Access.h"

#include "Vorpsoc_top.h"
#include "Vorpsoc_top_orpsoc_top.h"

#include "Vorpsoc_top_or1200_top.h"
#include "Vorpsoc_top_or1200_cpu.h"
#include "Vorpsoc_top_or1200_ctrl.h"
#include "Vorpsoc_top_or1200_except.h"
#include "Vorpsoc_top_or1200_sprs.h"
#include "Vorpsoc_top_or1200_rf.h"
#include "Vorpsoc_top_or1200_dpram.h"

//! Constructor for the ORPSoC access class

//! Initializes the pointers to the various module instances of interest
//! within the Verilator model.

//! @param[in] orpsoc  The SystemC Verilated ORPSoC instance

OrpsocOr1200Access::OrpsocOr1200Access(Vorpsoc_top * orpsoc_top)
{
	// Assign processor accessor objects
	or1200_ctrl = orpsoc_top->v->or1200_top0->or1200_cpu->or1200_ctrl;
	or1200_except = orpsoc_top->v->or1200_top0->or1200_cpu->or1200_except;
	or1200_sprs = orpsoc_top->v->or1200_top0->or1200_cpu->or1200_sprs;
	rf_a = orpsoc_top->v->or1200_top0->or1200_cpu->or1200_rf->rf_a;
}				// OrpsocOr1200Access ()


//! Access for the ex_freeze signal

//! @return  The value of the or1200_ctrl.ex_freeze signal

bool OrpsocOr1200Access::getExFreeze()
{
	return or1200_ctrl->ex_freeze;

}				// getExFreeze ()

//! Access for the wb_freeze signal

//! @return  The value of the or1200_ctrl.wb_freeze signal

bool OrpsocOr1200Access::getWbFreeze()
{
	return or1200_ctrl->wb_freeze;

}				// getWbFreeze ()

//! Access for the except_flushpipe signal

//! @return  The value of the or1200_except.except_flushpipe signal

bool OrpsocOr1200Access::getExceptFlushpipe()
{
	return or1200_except->except_flushpipe;

}				// getExceptFlushpipe ()

//! Access for the ex_dslot signal

//! @return  The value of the or1200_except.ex_dslot signalfac

bool OrpsocOr1200Access::getExDslot()
{
	return or1200_except->ex_dslot;

}				// getExDslot ()

//! Access for the except_type value

//! @return  The value of the or1200_except.except_type register

uint32_t OrpsocOr1200Access::getExceptType()
{
	return (or1200_except->get_except_type) ();

}				// getExceptType ()

//! Access for the id_pc register

//! @return  The value of the or1200_except.id_pc register

uint32_t OrpsocOr1200Access::getIdPC()
{
	return (or1200_except->get_id_pc) ();

}				// getIdPC ()

//! Access for the ex_pc register

//! @return  The value of the or1200_except.id_ex register

uint32_t OrpsocOr1200Access::getExPC()
{
	return (or1200_except->get_ex_pc) ();

}				// getExPC ()

//! Access for the wb_pc register

//! @return  The value of the or1200_except.wb_pc register

uint32_t OrpsocOr1200Access::getWbPC()
{
	return (or1200_except->get_wb_pc) ();

}				// getWbPC ()

//! Access for the id_insn register

//! @return  The value of the or1200_ctrl.wb_insn register

uint32_t OrpsocOr1200Access::getIdInsn()
{
	return (or1200_ctrl->get_id_insn) ();

}				// getIdInsn ()

//! Access for the ex_insn register

//! @return  The value of the or1200_ctrl.ex_insn register

uint32_t OrpsocOr1200Access::getExInsn()
{
	return (or1200_ctrl->get_ex_insn) ();

}				// getExInsn ()

//! Access for the wb_insn register

//! @return  The value of the or1200_ctrl.wb_insn register

uint32_t OrpsocOr1200Access::getWbInsn()
{
	return (or1200_ctrl->get_wb_insn) ();

}				// getWbInsn ()

//! Access for the OR1200 GPRs

//! These are extracted from memory using the Verilog function

//! @param[in] regNum  The GPR whose value is wanted

//! @return            The value of the GPR

uint32_t OrpsocOr1200Access::getGpr(uint32_t regNum)
{
	return (rf_a->get_gpr) (regNum);

}				// getGpr ()

//! Access for the OR1200 GPRs

//! These are extracted from memory using the Verilog function

//! @param[in] regNum  The GPR whose value is wanted
//! @param[in] value   The value of GPR to write

void OrpsocOr1200Access::setGpr(uint32_t regNum, uint32_t value)
{
	(rf_a->set_gpr) (regNum, value);

}				// getGpr ()

//! Access for the sr register

//! @return  The value of the or1200_sprs.sr register

uint32_t OrpsocOr1200Access::getSprSr()
{
	return (or1200_sprs->get_sr) ();

}				// getSprSr ()

//! Access for the epcr register

//! @return  The value of the or1200_sprs.epcr register

uint32_t OrpsocOr1200Access::getSprEpcr()
{
	return (or1200_sprs->get_epcr) ();

}				// getSprEpcr ()

//! Access for the eear register

//! @return  The value of the or1200_sprs.eear register

uint32_t OrpsocOr1200Access::getSprEear()
{
	return (or1200_sprs->get_eear) ();

}				// getSprEear ()

//! Access for the esr register

//! @return  The value of the or1200_sprs.esr register

uint32_t OrpsocOr1200Access::getSprEsr()
{
	return (or1200_sprs->get_esr) ();

}				// getSprEsr ()

