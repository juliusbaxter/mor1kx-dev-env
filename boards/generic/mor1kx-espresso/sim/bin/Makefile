######################################################################
####                                                              ####
####  ORPSoCv2 Testbenches Makefile                               ####
####                                                              ####
####  Description                                                 ####
####  ORPSoCv2 Testbenches Makefile, containing rules for         ####
####  configuring and running different tests on the current      ####
####  ORPSoC(v2) design.                                          ####
####                                                              ####
####  To do:                                                      ####
####                                                              ####
####  Author(s):                                                  ####
####      - Julius Baxter, julius@opencores.org                   ####
####                                                              ####
####                                                              ####
######################################################################
####                                                              ####
#### Copyright (C) 2009,2010,2011 Authors and OPENCORES.ORG       ####
####                                                              ####
#### This source file may be used and distributed without         ####
#### restriction provided that this copyright statement is not    ####
#### removed from the file and that any derivative work contains  ####
#### the original copyright notice and the associated disclaimer. ####
####                                                              ####
#### This source file is free software; you can redistribute it   ####
#### and/or modify it under the terms of the GNU Lesser General   ####
#### Public License as published by the Free Software Foundation; ####
#### either version 2.1 of the License, or (at your option) any   ####
#### later version.                                               ####
####                                                              ####
#### This source is distributed in the hope that it will be       ####
#### useful, but WITHOUT ANY WARRANTY; without even the implied   ####
#### warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ####
#### PURPOSE.  See the GNU Lesser General Public License for more ####
#### details.                                                     ####
####                                                              ####
#### You should have received a copy of the GNU Lesser General    ####
#### Public License along with this source; if not, download it   ####
#### from http://www.opencores.org/lgpl.shtml                     ####
####                                                              ####
######################################################################

# Name of the directory we're currently in
CUR_DIR=$(shell pwd)

PRELOAD_RAM=1

# The root path of the whole project
BOARD_ROOT ?=$(CUR_DIR)/../..
# Makefile fragment with most of the setup
include $(BOARD_ROOT)/Makefile.inc

# Simulation-specific paths and files from this one
include $(PROJECT_ROOT)/scripts/make/Makefile-board-benchsrc.inc

# Software tests we'll run
TEST ?= or1k-basic
TESTS ?= mor1kx-version			\
	or1k-lsu			\
	or1k-rfe			\
	or1k-insnfetchalign		\
	or1k-insnfetcherror		\
	or1k-systemcall			\
	or1k-trap			\
        or1k-ov                         \
	or1k-cy				\
	or1k-trapdelayslot		\
	or1k-illegalinsn		\
	or1k-illegalinsndelayslot 	\
	or1k-lsualign			\
	or1k-lsualigndelayslot		\
	or1k-lsuerror			\
	or1k-lsuerrordelayslot		\
	or1k-alignillegalinsn		\
	or1k-lwjr			\
	or1k-shortbranch		\
	or1k-shortjump  		\
	or1k-cmov			\
	or1k-timer			\
	or1k-tickrfforward		\
	or1k-intloop    		\
	or1k-tickloop   		\
	or1k-dsx			\
	or1k-intsyscall			\
	or1k-ticksyscall		\
	or1k-ffl1			\
	or1k-sf				\
	or1k-simple			\
	or1k-basic			\
	or1k-cbasic			\
	uart-simple

DEBUG_UNIT_TESTS ?=			\
	mor1kx-debugsteptest		\
	mor1kx-debugbkpnttest		\
	mor1kx-debugexceptsteptest

# If we're running the rtl target, we can have the debug 
# unit tests.
ifeq ($(MAKECMDGOALS),rtl-tests)
TESTS += $(DEBUG_UNIT_TESTS)
endif

include $(PROJECT_ROOT)/scripts/make/Makefile-simulators.inc

# Gets turned into verilog `define
SIM_TYPE=RTL

SIMULATOR ?= $(ICARUS)

# Include the test-defines.v generation rule
include $(PROJECT_ROOT)/scripts/make/Makefile-sim-definesgen.inc

#
# Icarus make rules for RTL tests
#
include $(PROJECT_ROOT)/scripts/make/Makefile-board-icarus.inc

#
# RTL test rules
#
include $(PROJECT_ROOT)/scripts/make/Makefile-rtltestrules.inc

#
# Software make rules (called recursively)
#
include $(PROJECT_ROOT)/scripts/make/Makefile-board-sw.inc


#
# Verilator make rules
#
include $(PROJECT_ROOT)/scripts/make/Makefile-board-verilator.inc

#
# Cleaning rules
#
include $(PROJECT_ROOT)/scripts/make/Makefile-board-simclean.inc
