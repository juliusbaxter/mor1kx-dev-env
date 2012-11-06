// ----------------------------------------------------------------------------

// SystemC mor1kx Monitor: implementation

// Copyright (C) 2008  Embecosm Limited <info@embecosm.com>
// Copyright (C) 2011  Julius Baxter <juliusbaxter@gmail.com

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

#include <iostream>
#include <iomanip>
#include <fstream>
#include <sys/types.h>
#include <netinet/in.h>
using namespace std;

#include "Mor1kxMonitorSC.h"
#include "OrpsocMain.h"

#include <errno.h>
int monitor_to_gdb_pipe[2][2];	// [0][] - monitor to gdb, [1][] - gdb to 
				// monitor, [][0] - read, [][1] - write


static OrpsocMor1kxAccess * globalOrpsocAccessor;
static OrpsocMemoryAccess * globalMemoryAccessor;
#ifdef USE_OR1KTRACE
extern "C" {
#include <or1ktrace.h>
}
#endif

SC_HAS_PROCESS(Mor1kxMonitorSC);

long unsigned int
callback_getGpr(int gprnum)
{
  return (long unsigned int) globalOrpsocAccessor->getGpr(gprnum);
}

long unsigned int
callback_getSpr(int sprnum){
  switch(sprnum)
    {
    case 17:
      return (long unsigned int) globalOrpsocAccessor->getSprSr();
    case 32:
      return (long unsigned int) globalOrpsocAccessor->getSprEpcr();
    case 48:
      return (long unsigned int) globalOrpsocAccessor->getSprEear();
    case 64:
      return (long unsigned int) globalOrpsocAccessor->getSprEsr();
    default:
      return 0;
    }
}

#define SWAP_ENDIAN32(x)			\
      (((x>>24)&0xff)|				\
       ((x>>8)&0xff00)|				\
       ((x<<8)&0xff0000)|			\
       ((x<<24)&0xff000000))


unsigned long
callback_getMem32(unsigned long addr)
{
  return (unsigned long) SWAP_ENDIAN32(globalMemoryAccessor->get_mem32(addr));
}

//! Constructor for the mor1kx processor monitor

//! @param[in] name  Name of this module, passed to the parent constructor.
//! @param[in] accessor  Accessor class for this Verilated ORPSoC model

Mor1kxMonitorSC::Mor1kxMonitorSC(sc_core::sc_module_name name,
				 OrpsocMor1kxAccess * _accessor,
				 OrpsocMemoryAccess * _memaccessor,
				 MemoryLoad * _memoryload,
				 uint32_t* _returnCode,
				 int argc,
				 char *argv[]):sc_module(name),
					       accessor(_accessor),
					       memaccessor(_memaccessor), 
					       memoryload(_memoryload)
{

  /* Assign defaults */
  globalOrpsocAccessor = _accessor;
  globalMemoryAccessor = _memaccessor;
  string logfileDefault(DEFAULT_EXEC_LOG_FILE);
  string logfileNameString;
  trace_enabled = false;
  logging_enabled = false;
  logfile_name_provided = false;
  profiling_enabled = false;
  string profileFileName(DEFAULT_PROF_FILE);
  memdumpFileName = (DEFAULT_MEMDUMP_FILE);
  int memdump_start = -1;
  int memdump_end = -1;
  do_memdump = false;	// Default is not to do a dump of RAM at finish
  logging_regs = true;	// Execution log has GPR values by default
  bool rsp_server_enabled = false;
  wait_for_stall_cmd_response = false;	// Default
  insn_count = insn_count_rst = 0;
  cycle_count = cycle_count_rst = 0;
  
  // Store pointer to the return code for the sim
  returnCode = _returnCode;

  perf_summary = false;
  monitor_for_crash = false;
  lookslikewevecrashed_count = crash_monitor_buffer_head = 0;

  bus_trans_log_enabled = bus_trans_log_name_provided = bus_trans_log_start_delay_enable = false;	// Default
  string bus_trans_default_log_name(DEFAULT_BUS_LOG_FILE);
  string bus_trans_log_file;

  // Parse the command line options
  bool cmdline_name_found = false;

  /*  Search through the command line parameters for the "-log" option */
  for (int i = 1; i < argc && argc > 1; i++) {
    if ((strcmp(argv[i], "-l") == 0) ||
	(strcmp(argv[i], "--log") == 0)) {
      logging_enabled = true;
      binary_log_format = false;
      if (i + 1 < argc)
	if (argv[i + 1][0] != '-') {
	  logfileNameString = (argv[i + 1]);
	  logfile_name_provided = true;
	}
      if (!logfile_name_provided)
	logfileNameString = logfileDefault;
    } else if ((strcmp(argv[i], "--log-noregs") == 0)) {
      logging_regs = false;
    } else if ((strcmp(argv[i], "--trace") == 0)) {
      trace_enabled = true;

    } else if ((strcmp(argv[i], "-b") == 0) ||
	       (strcmp(argv[i], "--binlog") == 0)) {
      logging_enabled = true;
      binary_log_format = true;
      if (i + 1 < argc)
	if (argv[i + 1][0] != '-') {
	  logfileNameString = (argv[i + 1]);
	  logfile_name_provided = true;
	}
      if (!logfile_name_provided)
	logfileNameString = logfileDefault;

    } else if ((strcmp(argv[i], "-c") == 0) ||
	       (strcmp(argv[i], "--crash-monitor") == 0)) {
      monitor_for_crash = true;
    } else if ((strcmp(argv[i], "-u") == 0) ||
	       (strcmp(argv[i], "--summary") == 0)) {
      perf_summary = true;
    } else if ((strcmp(argv[i], "-p") == 0) ||
	       (strcmp(argv[i], "--profile") == 0)) {
      profiling_enabled = true;
      // Check for !end of command line and that 
      // next thing is not a command
      if ((i + 1 < argc)) {
	if (argv[i + 1][0] != '-')
	  profileFileName = (argv[i + 1]);
      }
    } else if ((strcmp(argv[i], "-r") == 0) ||
	       (strcmp(argv[i], "--rsp") == 0)) {
      // We need to detect this here too
      rsp_server_enabled = true;
    }

    else if ((strcmp(argv[i], "-m") == 0) ||
	     (strcmp(argv[i], "--memdump") == 0)) {
      do_memdump = true;
      /* Check for !end of command line and that next thing 
	 is not a  command or a memory address.
      */
      if (i + 1 < argc) {
	if ((argv[i + 1][0] != '-')
	    && (strncmp("0x", argv[i + 1], 2) != 0)) {
	  /* Hopefully this is the filename we 
	     want to use. All addresses should 
	     have preceeding hex identifier 0x 
	  */
	  memdumpFileName = argv[i + 1];
	  /* We've used this next index, can 
	     safely increment i 
	  */
	  i++;
	}
      }
      if (i + 1 < argc) {
	if ((argv[i + 1][0] != '-')
	    && (strncmp("0x", argv[i + 1], 2) == 0)) {
	  sscanf(argv[i + 1], "0x%x",
		 &memdump_start);
	  i++;
	}
      }
      if (i + 1 < argc) {
	if ((argv[i + 1][0] != '-')
	    && (strncmp("0x", argv[i + 1], 2) == 0)) {
	  sscanf(argv[i + 1], "0x%x",
		 &memdump_end);
	  i++;
	}
      }
    }
  }

  if (!rsp_server_enabled) {
    monitor_to_gdb_pipe[0][0] = monitor_to_gdb_pipe[0][1] = 0;
    monitor_to_gdb_pipe[1][0] = monitor_to_gdb_pipe[1][1] = 0;
  }
  /* checkInstruction monitors the bus for special NOP instructionsl */
  SC_METHOD(checkInstruction);
  sensitive << clk.neg();
  dont_initialize();

  if (profiling_enabled) {
    // Open profiling log file
    profileFile.open(profileFileName.c_str(), ios::out);
    if (profileFile.is_open()) {
      /* If the file was opened OK, then enabled logging and 
	 print a message.
      */
      profiling_enabled = true;
      cout << "* Execution profiling enabled. Logging to " <<
	profileFileName << endl;
    }
    // Setup profiling function
    /*
    SC_METHOD(callLog);
    sensitive << clk.pos();
    dont_initialize();		
    */
  }

  if (logging_enabled) {

    /* Now open the file */
    if (binary_log_format)
      statusFile.open(logfileNameString.c_str(),
		      ios::out | ios::binary);
    else
      statusFile.open(logfileNameString.c_str(), ios::out);

    /* Check the open() */
    if (statusFile.is_open() && binary_log_format) {
      cout <<
	"* Processor execution logged in binary format to file: "
	   << logfileNameString << endl;
      /* Write out a byte indicating whether there's register
	 values too 
      */
      statusFile.write((char *)&logging_regs, 1);

    } else if (statusFile.is_open() && !binary_log_format)
      cout << "* Processor execution logged to file: " <<
	logfileNameString << endl;
    else
      /* Couldn't open */
      logging_enabled = false;

  }

  if (logging_enabled) {
    /*
    if (binary_log_format) {
      SC_METHOD(displayStateBinary);
    } else {
    SC_METHOD(displayState);
    }
    */
    SC_METHOD(displayState);
    sensitive << clk.pos();
    dont_initialize();
    start = clock();

  }

  if (monitor_for_crash) {
    cout << "* Crash monitor enabled" << endl;
  }

  if (do_memdump) {
    // Were we given dump addresses? If not, we dump all of the 
    // memory. Size of memory isn't clearly defined in any one 
    // place. This could lead to big problems when changing size of
    // the RAM in simulation.
		
    /* No memory dump beginning specified. Set to zero. */
    if (memdump_start == -1)
      memdump_start = 0;
		
    /* No dump end specified, assign some token amount, probably
       useless, but then the user should have specified more. */
    if (memdump_end == -1)
      memdump_end = memdump_start + 0x2000;

    if (memdump_start & 0x3)
      memdump_start &= ~0x3;	// word-align the start address      
    if (memdump_end & 0x3)
      memdump_end = (memdump_end + 4) & ~0x3;	// word-align the start address

    memdump_start_addr = memdump_start;
    memdump_end_addr = memdump_end;
  }

  if (trace_enabled)
    {
#ifdef USE_OR1KTRACE
      or1ktrace_init(callback_getMem32, callback_getGpr, callback_getSpr, 0);
#endif
    }

  // Record roughly when we begin execution
  start = clock();

}				// Mor1kxMonitorSC ()

//! Print usage for the options of this module
void
Mor1kxMonitorSC::printUsage()
{
  printf("\nLogging and diagnostic options:\n");
  printf("      --trace\t\tEnable an execution trace to stdout during simulation\n");
  printf("  -u, --summary\t\tEnable summary on exit\n");
  printf
    ("  -p, --profile [<file>]\n\t\t\tEnable execution profiling output to <file> (default is\n\t\t\t"
     DEFAULT_PROF_FILE ")\n");
  printf("  -l, --log <file>\tLog processor execution to <file>\n");
  printf("      --log-noregs\tLog excludes register contents\n");

  printf
    ("  -b, --binlog <file>\tGenerate binary format execution log (faster, smaller)\n");

  printf
    ("  -m, --memdump <file> <0xstartaddr> <0xendaddr>\n\t\t\tDump data between <0xstartaddr> and <0xendaddr> from\n\t\t\tthe system's RAM to <file> in binary format on exit\n");
  printf
    ("  -c, --crash-monitor\tDetect when the processor has crashed and exit\n");

}

//! Method to handle special instrutions

//! These are l.nop instructions with constant values. At present the
//! following are implemented:

//! - l.nop 1  Terminate the program
//! - l.nop 2  Report the value in R3
//! - l.nop 3  Printf the string with the arguments in R3, etc (DEPRECATED)
//! - l.nop 4  Print a character

#define OR1K_NOP_INSN_TOP_BYTE 0x15
#define OR1K_NOP 0x14000000

void 
Mor1kxMonitorSC::checkInstruction()
{
  uint32_t r3;
  double ts;
  static uint32_t decodeInsn = OR1K_NOP, executeInsn = OR1K_NOP,
    executeInsnDelayed = OR1K_NOP;
  static uint32_t executePCDelayed;
  uint32_t exPC;
  clock_t now;
  double elapsedTime;
  int hertz, khertz;
  unsigned long long int psPeriod;
  char insnMSByte;
  uint32_t insnImm;
  char disastr[100];
  static bool executeAdvDelayed = 0;
  cycle_count++;
  //cout << "cycle_count++ " << cycle_count << endl;

  if (accessor->getExAdv()){

    executeInsn = accessor->getExInsn();
    insn_count++;
    //cout << "insn!" << endl;

#ifdef USE_OR1KTRACE
    if (trace_enabled)
      {
	or1ktrace_gen_trace_string(accessor->getExPC(), disastr);
	cout << disastr << endl;
      }
#endif

    // Extract MSB of instruction
    insnMSByte = (executeInsn >> 24) & 0xff;
		
    if (insnMSByte == OR1K_NOP_INSN_TOP_BYTE)
      {
	insnImm = executeInsn & 0xffff;
	
	// Do something if we have l.nop
	switch (insnImm) {

	case NOP_EXIT:
	  r3 = accessor->getGpr(3);
	  *returnCode = (uint32_t) r3;
	  /* No timestamp with reports, so exit report is
	     same format as from or1ksim */
	  std::
	    cout << "exit(" << r3 << ")" <<
	    std::endl;
	  if (perf_summary)
	    perfSummary();

	  if (logging_enabled)
	    statusFile.close();
	  if (profiling_enabled)
	    profileFile.close();
	  if (bus_trans_log_enabled)
	    busTransLog.close();
	  memdump();
	  gSimRunning = 0;
	  sc_stop();
	  break;

	case NOP_REPORT:
	  /* No timestamp with reports, so reports are
	     same format as from or1ksim */
	  r3 = accessor->getGpr(3);
	  std::cout << "report(0x" << 
	    std::setfill('0') << hex << 
	    std::setw(8) << r3 << ");" << std::endl;
	  break;

	case NOP_PRINTF:
	  //std::cout << "printf: ";
	  std::cout << "printf via l.nop DEPRECATED" << std::endl;
	  //simPrintf(accessor->getGpr(4), accessor->getGpr(3));
	  break;

	case NOP_PUTC:
	  r3 = accessor->getGpr(3);
	  std::cout << (char)r3 << std::flush;
	  break;

	case NOP_GET_TICKS:
	  // Put number of cycles so far into r11 and r12
	  accessor->setGpr(11, (uint32_t) cycle_count&0xffffffff);
	  accessor->setGpr(12, (uint32_t) (cycle_count >> 32) & 
			   0xffffffff);
	  break;
	case NOP_GET_PS:
	  // Put PS/cycle into r11
	  now = clock();
	  elapsedTime =
	    (double (now) - double (start))/CLOCKS_PER_SEC;

	  // Calculate execution rate so far
	  khertz = (int)((cycle_count / elapsedTime) / 1000);
			
	  psPeriod 
	    = (((unsigned long long int) 1000000000) / 
	       (unsigned long long int ) khertz);
			
	  accessor->setGpr(11, (uint32_t) psPeriod);
	  break;

	case NOP_CNT_RESET:
	  if (!gQuiet) {
	    std::cout <<
	      "****************** counters reset ******************"
		      << endl;
	    std::cout << "since last reset: cycles " <<
	      cycle_count -
	      cycle_count_rst << ", insn #" << insn_count
	      - insn_count_rst << endl;
	    std::cout <<
	      "****************** counters reset ******************"
		      << endl;
	    cycle_count_rst = cycle_count;
	    insn_count_rst = insn_count;
	    /* 3 separate counters we'll use for various things */
	  }
	case NOP_CNT_RESET1:
	  if (!gQuiet) {
	    std::cout << "**** counter1 cycles: " <<
	      std::setfill('0') << std::setw(10) <<
	      cycle_count -
	      cycles_1 << " resetting ********" << endl;
	    cycles_1 = cycle_count;
	  }
	  break;
	case NOP_CNT_RESET2:
	  if (!gQuiet) {
	    std::cout << "**** counter2 cycles: " <<
	      std::setfill('0') << std::setw(10) <<
	      cycle_count -
	      cycles_2 << " resetting ********" << endl;
	    cycles_2 = cycle_count;
	  }
	  break;
	case NOP_CNT_RESET3:
	  if (!gQuiet) {
	    std::cout << "**** counter3 cycles: " <<
	      std::setfill('0') << std::setw(10) <<
	      cycle_count -
	      cycles_3 << " resetting ********" << endl;
	    cycles_3 = cycle_count;
	  }
	  break;

	case NOP_EXIT_SILENT:
	  r3 = accessor->getGpr(3);
	  *returnCode = (uint32_t) r3;
	  if (perf_summary)
	    perfSummary();
	  if (logging_enabled)
	    statusFile.close();
	  if (profiling_enabled)
	    profileFile.close();
	  if (bus_trans_log_enabled)
	    busTransLog.close();
	  memdump();
	  gSimRunning = 0;
	  sc_stop();
	  break;


	default:
	  break;
	}
		
      }

    if (monitor_for_crash) {
      exPC = accessor->getExPC();
      // Look at current instruction
      if (executeInsn == 0x00000000) {
	// Looks like we've jumped somewhere incorrectly
	lookslikewevecrashed_count++;
      }
      else if (((insnMSByte != OR1K_NOP_INSN_TOP_BYTE))
	       || !(executeInsn & (1 << 16))) {

	crash_monitor_buffer[crash_monitor_buffer_head]
	  [0] = exPC;
	crash_monitor_buffer[crash_monitor_buffer_head]
	  [1] = executeInsn;
	/* Circular buffer */
	if (crash_monitor_buffer_head <
	    CRASH_MONITOR_BUFFER_SIZE - 1)
	  crash_monitor_buffer_head++;
	else
	  crash_monitor_buffer_head = 0;

	/* Reset this */
	lookslikewevecrashed_count = 0;
      }
      if (wait_for_stall_cmd_response) {
	// We've already crashed, and we're issued a command to stall the
	// processor to the system C debug unit interface, and we're
	// waiting for this debug unit to send back the message that we've
	// stalled.
	char readChar;
	int n =
	  read(monitor_to_gdb_pipe[1][0], &readChar,
	       sizeof(char));
	if (!(((n < 0) && (errno == EAGAIN))
	      || (n == 0)))
	  wait_for_stall_cmd_response = false;	// We got response
	lookslikewevecrashed_count = 0;

      } else if (lookslikewevecrashed_count > 0) {

	if (lookslikewevecrashed_count >=
	    CRASH_MONITOR_BUFFER_SIZE / 4) {
	  /* Probably crashed. Bail out, print out buffer */
	  std::cout <<
	    "********************************************************************************"
		    << endl;
	  std::cout <<
	    "* Looks like processor crashed. Printing last "
		    << CRASH_MONITOR_BUFFER_SIZE <<
	    " instructions executed:" << endl;

	  int crash_monitor_buffer_head_end =
	    (crash_monitor_buffer_head >
	     0) ? crash_monitor_buffer_head -
	    1 : CRASH_MONITOR_BUFFER_SIZE - 1;
	  while (crash_monitor_buffer_head !=
		 crash_monitor_buffer_head_end) {
	    std::cout << "* PC: " <<
	      std::setfill('0') << hex <<
	      std::setw(8) <<
	      crash_monitor_buffer
	      [crash_monitor_buffer_head]
	      [0] << "  INSN: " <<
	      std::setfill('0') << hex <<
	      std::setw(8) <<
	      crash_monitor_buffer
	      [crash_monitor_buffer_head]
	      [1] << endl;

	    if (crash_monitor_buffer_head <
		CRASH_MONITOR_BUFFER_SIZE -
		1)
	      crash_monitor_buffer_head++;
	    else
	      crash_monitor_buffer_head
		= 0;
	  }
	  std::cout <<
	    "********************************************************************************"
		    << endl;

	  if (monitor_to_gdb_pipe[0][0]) {
	    // If GDB server is running, we'll pass control back to
	    // the debugger instead of just quitting.
	    char interrupt = 0x3;	// Arbitrary
	    if (write(monitor_to_gdb_pipe[0][1], &interrupt, sizeof(char)) < 0)
		    std::cout << "Write to GDB failed\n";
	    wait_for_stall_cmd_response =
	      true;
	    lookslikewevecrashed_count = 0;
	    std::cout <<
	      "* Stalling processor and returning control to GDB"
		      << endl;
	    // Problem: the debug unit interface's stalling the processor over the simulated JTAG bus takes a while, in the meantime this monitor will continue running and keep triggering the crash detection code. We must somehow wait until the processor is stalled, or circumvent this crash detection output until we detect that the processor is stalled.
	    // Solution: Added another pipe, when we want to wait for preocssor to stall, we set wait_for_stall_cmd_response=true, then each time we get back to this monitor function we simply poll the pipe until we're stalled. (A blocking read didn't work - this function never yielded and the RSP server handling function never got called).
	    wait_for_stall_cmd_response =
	      true;

	  } else {
	    // Close down sim end exit
	    ts = sc_time_stamp().to_seconds
	      () * 1000000000.0;
	    std::cout << std::fixed <<
	      std::setprecision(2) << ts;
	    std::cout << " ns: Exiting (" <<
	      r3 << ")" << std::endl;
	    if (perf_summary)
	      perfSummary();
	    if (logging_enabled)
	      statusFile.close();
	    if (profiling_enabled)
	      profileFile.close();
	    if (bus_trans_log_enabled)
	      busTransLog.close();
	    memdump();
	    gSimRunning = 0;
	    *returnCode = (uint32_t) 1;
	    sc_stop();
	  }
	}
      }
    }
  }
}				// checkInstruction()

//! Method to output the state of the processor

//! This function will output to a file, if enabled, the status of the processor
//! This copies what the verilog testbench module, mor1kx_monitor does in it its
//! process which calls the display_arch_state tasks. This is designed to be 
//! identical to that process, so the output is identical

void 
Mor1kxMonitorSC::displayState()
{
  uint32_t decodeInsn, executeInsn;

  if (accessor->getExAdv()){

    executeInsn = decodeInsn;

    // Print PC, instruction
    statusFile << "\nEXECUTED(" << std::setfill(' ') <<
      std::setw(11) << dec << insn_count << "): " <<
      std::
      setfill('0') << hex << std::setw(8) << accessor->getExPC() << 
      ":  " << hex << std::
      setw(8) << executeInsn << endl;
  }

  if (logging_regs) {
    // Print general purpose register contents
    for (int i = 0; i < 32; i++) {
      if ((i % 4 == 0) && (i > 0))
	statusFile << endl;
      statusFile << std::setfill('0');
      statusFile << "GPR" << dec << std::setw(2) << i << ": "
		 << hex << std::
	setw(8) << (uint32_t) accessor->getGpr(i) << "  ";
    }
    statusFile << endl;

    statusFile << "SR   : " << hex << std::setw(8) << (uint32_t)
      accessor->getSprSr() << "  ";
    statusFile << "EPCR0: " << hex << std::setw(8) << (uint32_t)
      accessor->getSprEpcr() << "  ";
    statusFile << "EEAR0: " << hex << std::setw(8) << (uint32_t)
      accessor->getSprEear() << "  ";
    statusFile << "ESR0 : " << hex << std::setw(8) << (uint32_t)
      accessor->getSprEsr() << endl;

  }

  if (accessor->getIdAdv())
    decodeInsn = accessor->getIdInsn();

  return;

}				// displayState()

//! Method to output the state of the processor in binary format
//! File format is simply first byte indicating whether register
//! data is included, and then structs of the following type
struct s_binary_output_buffer {
  long long insn_count;
  uint32_t pc;
  uint32_t insn;
  char exception;
  uint32_t regs[32];
  uint32_t sr;
  uint32_t epcr0;
  uint32_t eear0;
  uint32_t eser0;
} __attribute__ ((__packed__));

struct s_binary_output_buffer_sans_regs {
  long long insn_count;
  uint32_t pc;
  uint32_t insn;
  char exception;
} __attribute__ ((__packed__));


//! Function to calculate the number of instructions performed and the time taken
void 
Mor1kxMonitorSC::perfSummary()
{
  double ts;
  ts = sc_time_stamp().to_seconds() * 1000000000.0;
  int cycles = ts / (BENCH_CLK_HALFPERIOD * 2);	// Number of clock cycles we had
	
  clock_t finish = clock();
  double elapsedTime =
    (double (finish) - double (start))/CLOCKS_PER_SEC;
  // It took elapsedTime seconds to do insn_count instructions. Divide 
  // insn_count by the time to get instructions/second.
  double ips = (insn_count / elapsedTime);
  double kips = (insn_count / elapsedTime) /1000;
  double mips = (insn_count / elapsedTime) / 1000000;
  int hertz = (int)((cycles / elapsedTime) / 1000);
  std::cout << "* Mor1kxMonitor: simulator time at exit: " << ts 
	    << " ns" << endl;
  std::cout << "* Mor1kxMonitor: system time elapsed: " << elapsedTime 
	    << " seconds" << endl;
  std::cout << "* Mor1kxMonitor: simulated " << dec << cycles <<
    " clock cycles, executed at approx " << hertz << "kHz" <<
    endl;
  std::cout << "* Mor1kxMonitor: simulated " << insn_count <<
    " instructions, 1000's insn/sec. = " << kips << endl;
  return;
}				// perfSummary

//! Dump contents of simulation's RAM to file
void 
Mor1kxMonitorSC::memdump()
{
  if (!do_memdump)
    return;
  uint32_t current_word;
  int size_words = (memdump_end_addr / 4) - (memdump_start_addr / 4);
  if (!(size_words > 0))
    return;

  // First try opening the file
  memdumpFile.open(memdumpFileName.c_str(), ios::binary);	// Open memorydump file
  if (memdumpFile.is_open()) {
    // If we could open the file then turn on logging
    cout << "* Dumping system RAM from  0x" << hex <<
      memdump_start_addr << "-0x" << hex << memdump_end_addr <<
      " to file " << memdumpFileName << endl;

    while (size_words) {
      // Read the data from the simulation memory
      current_word = memaccessor->get_mem32(memdump_start_addr);
      // Change from whatever endian the host is (most
      // cases little) to big endian
      current_word = htonl(current_word);
      memdumpFile.write((char *)&current_word, 4);
      memdump_start_addr += 4;
      size_words--;
    }

    // Ideally we've now finished piping out the data
    // not 100% about the endianess of this.
  }
  memdumpFile.close();

}

