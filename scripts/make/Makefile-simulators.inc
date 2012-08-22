# Various simulator commands

ifeq ($(V),1)
ICARUS_VERBOSE_COMPILE=-Wall -Winfloop -Wno-timescale
endif

ifeq ($(LXT),1)
ICARUS_LXT_DUMP=-lxt +LXT
endif

# Icarus verilog commands
ICARUS_COMPILE=iverilog $(ICARUS_VERBOSE_COMPILE)
ICARUS_RUN=vvp
ICARUS_SCRIPT=icarus.scr
ICARUS_SIM_EXE=vlogsim.elf
ICARUS=icarus


# Modelsim variables
MGC_VSIM=vsim
MGC_VLOG_COMP=vlog
MGC_VHDL_COMP=vcom
MODELSIM=modelsim
