# Makefile fragment with some variables global to this board board
# Expects BOARD_ROOT to be set

FPGA_VENDOR=generic
BOARD_NAME=mor1kx
BOARD=$(FPGA_VENDOR)/$(BOARD_NAME)
DESIGN_NAME=orpsoc

export BOARD

MOR1KX_CPU=cappuccino

# Path down to root of project
PROJECT_ROOT=$(BOARD_ROOT)/../../..

# This selects the sw driver for low-level things
OPENRISC_CPU_DRIVER=mor1kx
export OPENRISC_CPU_DRIVER

OR32_TOOL_PREFIX=or1k-elf-
export OR32_TOOL_PREFIX

include $(PROJECT_ROOT)/scripts/make/Makefile-misc.inc
include $(PROJECT_ROOT)/scripts/make/Makefile-board-paths.inc
include $(PROJECT_ROOT)/scripts/make/Makefile-board-tops.inc
include $(PROJECT_ROOT)/scripts/make/Makefile-board-definesparse.inc

# Null entries for bootrom
BOOTROM_SW_DIR=/tmp
bootrom:
	$(Q)echo
clean-bootrom:
	$(Q)echo

include $(PROJECT_ROOT)/scripts/make/Makefile-board-rtlmodules.inc
