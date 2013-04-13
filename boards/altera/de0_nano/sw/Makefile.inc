# Expecting BOARD_SW_ROOT already set to indicate how far below directory we're
# in the board's software root path is.
BOARD_ROOT=$(BOARD_SW_ROOT)/..

include $(BOARD_ROOT)/Makefile.inc

# Root from the board's sw/ path
PROJ_ROOT=../../../..

# Figure out actual path the common software directory
SW_ROOT=$(BOARD_SW_ROOT)/$(PROJ_ROOT)/sw

# Set the BOARD to be the path within the board/ path of the project that goes
# to this project.
BOARD=altera/de0_nano

# Set RTL_VERILOG_INCLUDE_DIR so software
RTL_VERILOG_INCLUDE_DIR=$(shell pwd)/$(BOARD_SW_ROOT)/../rtl/verilog/include

# Finally include the main software include file

include $(SW_ROOT)/Makefile.inc
