# Icarus script fragment for builds under the boards/ path

# VPI debugging interface set up
VPI_SRC_C_DIR=$(COMMON_BENCH_VERILOG_DIR)/vpi/c
VPI_SRCS=$(shell ls $(VPI_SRC_C_DIR)/*.[ch])
# Icarus VPI compile target
ICARUS_VPILIB=jp_vpi

ifeq ($(VPI), 1)
ICARUS_VPI_LIB=$(VPI_SRC_C_DIR)/$(ICARUS_VPILIB)
ICARUS_VPI_ARGS=-M$(VPI_SRC_C_DIR) -m$(ICARUS_VPILIB)
endif

ifeq ($(MOR1KX_CPU),)
MOR1KX_CPU=fourstage
endif
ifneq ($(MOR1KX_CPU_WRAPPER_PATH),)
MOR1KX_CPU_WRAPPER_DEFINE="+define+CPU_WRAPPER="$(MOR1KX_CPU_WRAPPER_PATH)
endif

# Rule to make VPI library for Icarus Verilog
$(ICARUS_VPI_LIB): $(VPI_SRCS)
	$(MAKE) -C $(VPI_SRC_C_DIR) $(ICARUS_VPILIB)

# Manually add the VPI bench verilog path
BENCH_VERILOG_SRC_SUBDIRS += $(VPI_SRC_VERILOG_DIR)

#
# Icarus Verilog simulator build and run rules
#
.PHONY: $(ICARUS_SCRIPT)
$(ICARUS_SCRIPT):  $(RTL_VERILOG_SRC) $(RTL_VERILOG_INCLUDES) \
		$(BOOTROM_VERILOG) $(BENCH_VERILOG_SRC)
	$(Q)echo "# Icarus Verilog simulation script" > $@
	$(Q)echo "# Auto generated. Any alterations will be written over!" >> $@
	$(Q)echo "+incdir+"$(BOARD_RTL_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo "+incdir+"$(BOOTROM_SW_DIR) >> $@;
	$(Q)echo "+incdir+"$(BOARD_BENCH_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo "+libext+.v" >> $@;
	$(Q)for module in $(BOARD_RTL_VERILOG_MODULES); do if [ -d $(BOARD_RTL_VERILOG_DIR)/$$module ]; then echo "-y " $(BOARD_RTL_VERILOG_DIR)/$$module >> $@; fi; done
	$(Q)for module in $(COMMON_RTL_VERILOG_MODULES); do if [ -d $(COMMON_RTL_VERILOG_DIR)/$$module ]; then echo "-y " $(COMMON_RTL_VERILOG_DIR)/$$module >> $@; fi; done
	$(Q)echo "+incdir+"$(BOARD_BENCH_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo "+incdir+"$(COMMON_BENCH_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo "+define+MOR1KX_CPU_PIPELINE="$(MOR1KX_CPU) >> $@;
	$(Q)echo $(MOR1KX_CPU_WRAPPER_DEFINE) >> $@;
	$(Q)echo "-y "$(BOARD_BENCH_VERILOG_DIR) >> $@;
	$(Q)echo "-y "$(COMMON_BENCH_VERILOG_DIR) >> $@;
	$(Q)for path in $(BENCH_VERILOG_SUBDIRS); do echo "+incdir+"$$path >> $@; done
	$(Q)for path in $(BENCH_VERILOG_SUBDIRS); do echo "-y "$$path >> $@; done
	$(Q)echo "+incdir+"$(BOARD_RTL_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo $(BENCH_TOP_FILE) >> $@;
	$(Q) echo >> $@

# Icarus design compilation rule
$(ICARUS_SIM_EXE): $(ICARUS_SCRIPT) $(TEST_DEFINES_VLG) 
	$(Q)echo; echo "\t### Compiling ###"; echo
	$(Q) $(ICARUS_COMPILE) -s$(RTL_TESTBENCH_TOP_NAME) -Winfloop -c $< -o $@

# Icarus simulation run rule
$(ICARUS): $(ICARUS_SIM_EXE) $(ICARUS_VPI_LIB)
	$(Q)echo; echo "\t### Launching simulation ###"; echo
	$(Q) $(ICARUS_RUN) $(ICARUS_VPI_ARGS) -l ../out/$(ICARUS_RUN).log $< \
	$(ICARUS_LXT_DUMP) +trace_enable
