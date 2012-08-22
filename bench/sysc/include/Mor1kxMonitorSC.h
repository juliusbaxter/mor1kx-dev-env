// ----------------------------------------------------------------------------

// SystemC OpenRISC 1200 Monitor: definition

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

#ifndef MOR1KX_MONITOR_SC__H
#define MOR1KX_MONITOR_SC__H

#include <fstream>
#include <ctime>

#include "systemc.h"

#include "OrpsocMemoryAccess.h"
#include "OrpsocMor1kxAccess.h"
#include "MemoryLoad.h"

//! Monitor for special l.nop instructions

//! This class is based on the mor1kx_monitor.v of the Verilog test bench. It
//! wakes up on each posedge clock to check for "special" l.nop instructions,
//! which need processing.

class Mor1kxMonitorSC:public sc_core::sc_module {
public:

	// Constructor
	Mor1kxMonitorSC(sc_core::sc_module_name name,
			OrpsocMor1kxAccess * _accessor,
			OrpsocMemoryAccess * _memaccessor,			
			MemoryLoad * _memoryload, 
			uint32_t *_returnCode,
			int argc, char *argv[]);

	// Method to check instructions
	void checkInstruction();

	// Methods to setup and output state of processor to a file
	void displayState();
	void displayStateBinary();

	// Methods to generate trace to stdout
	void printTrace();

	// Methods to generate the call and return list during execution
	void callLog();

	// Method to calculate performance of the sim
	void perfSummary();

	// Method to print out the command-line switches for this module's options  
	void printSwitches();

	// Method to print out the usage for each option
	void printUsage();

	// Method to dump simulation's RAM contents at finish
	void memdump();

	//long unsigned int getSpr(int sprnum);

	// The ports
	sc_in < bool > clk;

private:

#define DEFAULT_EXEC_LOG_FILE "mor1kx_exec.log"
#define DEFAULT_PROF_FILE "sim.profile"
#define DEFAULT_MEMDUMP_FILE "vorpsoc_ram.dump"
#define DEFAULT_BUS_LOG_FILE "bus_trans.log"

	// Special NOP instructions
	static const uint32_t NOP_NOP = 0;	//!< Normal nop instruction
	static const uint32_t NOP_EXIT = 1;	//!< End of simulation
	static const uint32_t NOP_REPORT = 2;	//!< Simple report
	static const uint32_t NOP_PRINTF = 3;	//!< Simprintf instruction
	static const uint32_t NOP_PUTC = 4;	//!< Putc instruction
	static const uint32_t NOP_CNT_RESET = 5;	//!< Reset statistics counters
	static const uint32_t NOP_GET_TICKS = 6;	//!< Get # ticks running
	static const uint32_t NOP_GET_PS = 7;	//!< Get picosecs/cycle

	static const uint32_t NOP_CNT_RESET1 = 16;	/* Reset statistics counter 1 */
	static const uint32_t NOP_CNT_RESET2 = 17;	/* Reset statistics counter 2 */
	static const uint32_t NOP_CNT_RESET3 = 18;	/* Reset statistics counter 3 */
	static const uint32_t NOP_MEM_STATS_RESET = 32;	//!< Reset memory statistics counters
	static const uint32_t NOP_CNT_RESET_DIFFERENCE = 48;	//!< Reset stats counters, print 

	// Variables for processor status output
	ofstream statusFile;
	ofstream profileFile;
	bool profiling_enabled;
	bool trace_enabled;
	bool logging_enabled;
	bool logfile_name_provided;
	bool logging_regs;
	bool binary_log_format;
	bool perf_summary;
	bool monitor_for_crash;
	int lookslikewevecrashed_count, crash_monitor_buffer_head;
#define CRASH_MONITOR_BUFFER_SIZE 32
	uint32_t crash_monitor_buffer[CRASH_MONITOR_BUFFER_SIZE][2];	//PC, Insn
	bool wait_for_stall_cmd_response;
	unsigned long long insn_count, insn_count_rst;
	unsigned long long cycle_count, cycle_count_rst;
	unsigned long long cycles_1, cycles_2, cycles_3;	// Cycle counters for l.nop insns
	ofstream memdumpFile;
	string memdumpFileName;
	bool do_memdump;
	int memdump_start_addr, memdump_end_addr;
	bool bus_trans_log_enabled, bus_trans_log_name_provided,
	    bus_trans_log_start_delay_enable;
	sc_time bus_trans_log_start_delay;
	enum busLogStates { BUS_LOG_IDLE, BUS_LOG_WAIT_FOR_ACK };
	ofstream busTransLog;

	//! Time measurement variable - for calculating performance of the sim
	clock_t start;

	//! Pointer to the return code we'll pass back when finishing
	uint32_t *returnCode;

	//! The accessor for the Orpsoc instance
	OrpsocMor1kxAccess *accessor;
	OrpsocMemoryAccess *memaccessor;

	//! The memory loading object
	MemoryLoad *memoryload;

};				// Mor1kxMonitorSC ()

#endif // MOR1KX_MONITOR_SC__H
