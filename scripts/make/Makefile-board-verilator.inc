
SIM_VLT_DIR ?= $(SIM_DIR)/vlt
################################################################################
# Verilator model build rules
################################################################################

ifeq ($(USE_OR1KTRACE), 1)
ifeq (,$(OR1KTRACE_ROOT))
$(error USE_OR1KTRACE is set but OR1KTRACE_ROOT is not. Need it to know where to look for the or1ktrace libs and headers.)
endif
OR1KTRACE_CPPFLAGS=-I$(OR1KTRACE_ROOT)/include -DUSE_OR1KTRACE
VLT_CFLAGS += $(OR1KTRACE_CPPFLAGS)
OR1KTRACE_LDFLAGS=-L$(OR1KTRACE_ROOT)/lib -lor1ktrace
endif

VLT_EXE=Vorpsoc_top
VLT_SCRIPT=verilator.scr

# Script for Verilator
$(SIM_VLT_DIR)/$(VLT_SCRIPT): $(RTL_VERILOG_SRC) $(RTL_VERILOG_INCLUDES) \
				$(BOOTROM_VERILOG)
	$(Q)echo "\tGenerating Verilator script"
	$(Q)echo "+incdir+"$(BOARD_RTL_VERILOG_INCLUDE_DIR) > $@;
#	$(Q)echo "+incdir+"$(BOOTROM_SW_DIR) >> $@;
	$(Q)echo "+incdir+"$(RTL_SIM_RUN_DIR) >> $@;
	$(Q)echo "+incdir+"$(SIM_VLT_DIR) >> $@;
	$(Q)for module in $(BOARD_RTL_VERILOG_MODULES); do if [ -d $(BOARD_RTL_VERILOG_DIR)/$$module ]; then echo "-y " $(BOARD_RTL_VERILOG_DIR)/$$module >> $@; fi; done
	$(Q)for module in $(COMMON_RTL_VERILOG_MODULES); do if [ -d $(COMMON_RTL_VERILOG_DIR)/$$module ]; then echo "-y " $(COMMON_RTL_VERILOG_DIR)/$$module >> $@; fi; done
	$(Q)echo $(DUT_TOP_FILE) >> $@;
	$(Q) echo >> $@


SYSC_LIB_ARCH_DIR=$(shell ls $$SYSTEMC | grep "lib-")


# List of System C models - use this list to link the sources into the Verilator
# build directory
#SYSC_MODELS=OrpsocMemoryAccess OrpsocOr1200Access OrpsocMor1kxAccess MemoryLoad
SYSC_MODELS=OrpsocMemoryAccess  OrpsocMor1kxAccess MemoryLoad

ifdef VLT_LINT
VLT_FLAGS +=--lint-only
endif

ifdef VLT_DEBUG
VLT_DEBUG_COMPILE_FLAGS = -g
# Enabling the following generates a TON of debugging
# when running verilator. Not so helpful.
#VLT_FLAGS = --debug --dump-tree
VLT_SYSC_DEBUG_DEFINE = VLT_DEBUG=1
endif

# This will build a verilator model that will generate profiling information
# suitable for gprof
# Run it through gprof after exection with: gprof Vorpsoc_top > gprof.out
# then run this through the Verilator tool with:
# verilator_profcfunc gprof.out > vprof.out
ifdef VLT_EXECUTION_PROFILE_BUILD
VLT_CFLAGS +=-g -pg
# Maybe add these to VLT_CFLAGS: -ftest-coverage -fprofile-arcs
VLT_FLAGS +=-profile-cfuncs
endif

# If set on the command line we build the cycle accurate model which will 
# generate verilator-specific profiling information. This is useful for 
# checking the efficiency of the model - not really useful for checking code 
# or the function of the model.
ifdef VLT_DO_PERFORMANCE_PROFILE_BUILD
VLT_CFLAGS += -fprofile-generate -fbranch-probabilities -fvpt \
		-funroll-loops -fpeel-loops -ftracer
else
#VLT_CFLAGS +=-fprofile-use -Wcoverage-mismatch
VLT_CFLAGS +=-Wcoverage-mismatch
endif

# Set VLT_IN_GDB=1 when making if going to run the cycle accurate model 
# executable in GDB.
ifdef VLT_IN_GDB
VLT_CFLAGS +=-g -O0 
else
# The default optimisation flag applied to all of the cycle accurate model files
VLT_CFLAGS +=-O3
endif

ifdef MOR1KX_CPU
VLT_CFLAGS += -DMOR1KX_CPU_$(MOR1KX_CPU)
endif

ifdef SYSC_MOR1KX_CPU_WRAPPER
VLT_CFLAGS += -DMOR1KX_CPU_WRAPPER=\"$(SYSC_MOR1KX_CPU_WRAPPER)\"
endif

# VCD Enabled by default when building, enable it at runtime
VLT_FLAGS +=--trace --exe
TRACE_FLAGS=-DVM_TRACE=1 -I${SYSTEMPERL}/src

# Verilator tuning
# Inlining:
VLT_FLAGS +=--inline-mult 1
# Optimisation option for Verilator scripts
VLT_FLAGS +=-O3
# X-assign - at reset, all signals are set to random values, helps find 
# reset bugs
VLT_FLAGS +=-x-assign unique

VLT_TRACEOBJ = verilated_vcd_c


# This is the list of extra models we'll issue make commands for
# Included is the SystemPerl trace model
SYSC_MODELS_BUILD=$(SYSC_MODELS) $(VLT_TRACEOBJ)

# List of sources for rule sensitivity
SYSC_MODEL_SOURCES=$(shell ls $(COMMON_BENCH_SYSC_SRC_DIR)/*.cpp)
SYSC_MODEL_SOURCES +=$(shell ls $(COMMON_BENCH_SYSC_INCLUDE_DIR)/*.h)

VLT_MODULES_OBJS=$(shell for mod in $(SYSC_MODELS_BUILD); do \
		echo $(SIM_VLT_DIR)/$$mod.o; \
	done)

VLT_MODEL_LINKS=$(shell for SYSCMODEL in $(SYSC_MODELS); do \
		echo $(SIM_VLT_DIR)/$$SYSCMODEL.cpp; \
	done) 

# Make Verilator build path if it doesn't exist
$(SIM_VLT_DIR):
	mkdir -p $@

# Dummy files the RTL requires: timescale.v
DUMMY_FILES_FOR_VLT=$(SIM_VLT_DIR)/timescale.v
$(DUMMY_FILES_FOR_VLT):
	$(Q)for file in $@; do if [ ! -e $$file ]; then touch $$file; fi; done

build-vlt: $(SIM_VLT_DIR) $(DUMMY_FILES_FOR_VLT) $(VLT_MODEL_LINKS) \
	processed-verilog-headers-in-c-for-vlt  $(SIM_VLT_DIR)/$(VLT_EXE)

# Main Cycle-accurate build rule
prepare-vlt: build-vlt
	@echo;echo "\tCycle-accurate model compiled successfully"
	@echo;echo "\tRun the executable with the -h option for usage instructions:";echo
	$(SIM_VLT_DIR)/$(VLT_EXE) -h
	@echo;echo

$(SIM_VLT_DIR)/$(VLT_EXE): $(SIM_VLT_DIR)/lib$(VLT_EXE).a \
				$(SIM_VLT_DIR)/OrpsocMain.o
# Final linking of the simulation executable. Order of libraries here is 
# important!
	$(Q)echo; echo "\tGenerating simulation executable"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
		g++ $(VLT_DEBUG_COMPILE_FLAGS) \
		$(VLT_CFLAGS) -I$(COMMON_BENCH_SYSC_INCLUDE_DIR) -I$(SIM_VLT_DIR) \
		-I$(VERILATOR_ROOT)/include/vltstd \
		-I$(VERILATOR_ROOT)/include -I$(SYSTEMC)/include -o $(VLT_EXE) \
		-L. -L$(COMMON_BENCH_SYSC_SRC_DIR) -L$(SYSTEMC)/$(SYSC_LIB_ARCH_DIR) \
		OrpsocMain.o -l$(VLT_EXE) -lmodules -lsystemc \
		$(OR1KTRACE_LDFLAGS) -liberty -lz

# Now compile the top level systemC "testbench" module from the systemC source 
# path
$(SIM_VLT_DIR)/OrpsocMain.o: $(COMMON_BENCH_SYSC_SRC_DIR)/OrpsocMain.cpp
	@echo; echo "\tCompiling top level SystemC testbench"; echo
	cd $(SIM_VLT_DIR) && \
	g++ $(VLT_DEBUG_COMPILE_FLAGS) $(VLT_CFLAGS) $(TRACE_FLAGS) \
	-I$(COMMON_BENCH_SYSC_INCLUDE_DIR) -I$(SIM_VLT_DIR) \
	-I$(VERILATOR_ROOT)/include/vltstd \
	-I$(VERILATOR_ROOT)/include -I$(SYSTEMC)/include -c \
	$(COMMON_BENCH_SYSC_SRC_DIR)/OrpsocMain.cpp 

$(SIM_VLT_DIR)/lib$(VLT_EXE).a: $(SIM_VLT_DIR)/$(VLT_EXE)__ALL.a \
		$(VLT_MODULES_OBJS) $(SIM_VLT_DIR)/verilated.o
# Now archive all of the libraries from verilator witht he other modules we 
# might have
	@echo; echo "\tArchiving libraries into lib"$(VLT_EXE)".a"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	cp $(VLT_EXE)__ALL.a lib$(VLT_EXE).a && \
	ar rcs lib$(VLT_EXE).a verilated.o; \
	for SYSCMODEL in $(SYSC_MODELS_BUILD); do \
		ar rcs lib$(VLT_EXE).a $$SYSCMODEL.o; \
	done

$(SIM_VLT_DIR)/verilated.o: $(SYSC_MODEL_SOURCES)
	@echo; echo "\tCompiling verilated.o"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	export CXXFLAGS=$(VLT_DEBUG_COMPILE_FLAGS); \
	export USER_CPPFLAGS="$(VLT_CFLAGS)"; \
	export USER_LDDFLAGS="$(VLT_CFLAGS) $(OR1KTRACE_LDDFLAGS)"; \
	$(MAKE) -f $(VLT_EXE).mk verilated.o

print-sysmod-objs:
	$(Q)echo $(VLT_MODULES_OBJS):

$(VLT_MODULES_OBJS):
# Compile the module files
	@echo; echo "\tCompiling SystemC models"
	$(Q)cd $(SIM_VLT_DIR) && \
	for SYSCMODEL in $(SYSC_MODELS_BUILD); do \
		echo;echo "\t$$SYSCMODEL"; echo; \
		export CXXFLAGS=$(VLT_DEBUG_COMPILE_FLAGS); \
		export USER_CPPFLAGS="$(VLT_CFLAGS) -I$(COMMON_BENCH_SYSC_INCLUDE_DIR) -I$(COMMON_SW_DIR)/lib/include"; \
		export USER_LDDFLAGS="$(VLT_CFLAGS)"; \
		 $(MAKE) -f $(VLT_EXE).mk $$SYSCMODEL.o; \
	done	

$(SIM_VLT_DIR)/$(VLT_EXE)__ALL.a: $(SIM_VLT_DIR)/$(VLT_EXE).mk \
		$(SYSC_MODEL_SOURCES)
	@echo; echo "\tCompiling main design"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	export USER_CPPFLAGS="$(VLT_CFLAGS)"; \
	export USER_LDDFLAGS="$(VLT_CFLAGS)"; \
	$(MAKE) -f $(VLT_EXE).mk $(VLT_EXE)__ALL.a

$(SIM_VLT_DIR)/$(VLT_EXE).mk: $(SIM_VLT_DIR)/$(VLT_SCRIPT) \
		$(COMMON_BENCH_SYSC_SRC_DIR)/libmodules.a
# Now call verilator to generate the .mk files
	$(Q)echo; echo "\tGenerating makefiles with Verilator"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	verilator -language 1364-2001 --top-module orpsoc_top -Mdir . --sc \
	$(USER_VLT_FLAGS) $(VLT_FLAGS) -I$(COMMON_BENCH_SYSC_INCLUDE_DIR) -I$(COMMON_BENCH_SYSC_SRC_DIR) \
	-f $(SIM_VLT_DIR)/$(VLT_SCRIPT)

# SystemC modules library
$(COMMON_BENCH_SYSC_SRC_DIR)/libmodules.a:
	@echo; echo "\tCompiling SystemC modules"; echo
	export VLT_CFLAGS="$(VLT_CFLAGS)"; \
	export SCRIPT_INCDIRS=-I$(COMMON_SW_DIR)/lib/include; \
	$(MAKE) -C $(COMMON_BENCH_SYSC_SRC_DIR) \
	-f $(COMMON_BENCH_SYSC_SRC_DIR)/Modules.make $(VLT_SYSC_DEBUG_DEFINE) 

print-vlt-model-link-paths:
	$(Q)echo $(VLT_MODEL_LINKS)

$(VLT_MODEL_LINKS):
# Link all the required system C model files into the verilator work dir
	$(Q)for SYSCMODEL in $(SYSC_MODELS); do \
		if [ ! -e $(SIM_VLT_DIR)/$$SYSCMODEL.cpp ]; then \
		echo \
	"\tLinking SystemC model $$SYSCMODEL  Verilator model build path"; \
			ln -s $(COMMON_BENCH_SYSC_SRC_DIR)/$$SYSCMODEL.cpp \
				$(SIM_VLT_DIR)/$$SYSCMODEL.cpp; \
			ln -s $(COMMON_BENCH_SYSC_INCLUDE_DIR)/$$SYSCMODEL.h \
				$(SIM_VLT_DIR)/$$SYSCMODEL.h; \
		fi; \
	done


################################################################################
# Verilator model test rules
################################################################################


vlt-test: build-vlt clean-sim-test-sw sw
	$(SIM_VLT_DIR)/$(VLT_EXE) $(TEST)

vlt-tests:
	$(Q)for test in $(TESTS); do \
		export TEST=$$test; \
		$(MAKE) vlt-test; \
		if [ $$? -ne 0 ]; then break; fi; \
		echo; echo "\t### $$test test OK ###"; echo; \
	done



###############################################################################
# Verilator profiled model build rules
###############################################################################
# To run this, first run a "make prepare-vlt-profiled"
# This new make target copies athe results of the profiling back to the right
# paths before we create everything again
###############################################################################
.PHONY: prepare-vlt-profiled
prepare-vlt-profiled: $(SIM_VLT_DIR)/OrpsocMain.gcda \
	clean-vlt-after-profile-run \
	$(SIM_VLT_DIR) $(DUMMY_FILES_FOR_VLT) $(VLT_MODEL_LINKS) \
	$(SIM_VLT_DIR)/$(VLT_EXE)

$(SIM_VLT_DIR)/OrpsocMain.gcda: $(SIM_VLT_DIR)/$(VLT_EXE)-for-profiling
	$(MAKE) -C $(SW_DIR)/apps/dhry dhry.elf NUM_RUNS=5000
	$(SIM_VLT_DIR)/$(VLT_EXE) -f $(SW_DIR)/apps/dhry/dhry.elf

# Clean all compiled things
clean-vlt-after-profile-run:
	$(Q)echo "\tCleaning away compiled cycle-accurate files"
	$(Q)rm -f $(SIM_VLT_DIR)/*.[oa] $(SIM_VLT_DIR)/$(VLT_EXE)
	$(Q)rm -f $(COMMON_BENCH_SYSC_SRC_DIR)/*.[oa]

#.PHONY: $(SIM_VLT_DIR)/$(VLT_EXE)-for-profiling
$(SIM_VLT_DIR)/$(VLT_EXE)-for-profiling:
	$(MAKE) build-vlt VLT_DO_PERFORMANCE_PROFILE_BUILD=1

.PHONY: vlt-restore-profileoutput
vlt-restore-profileoutput:
	@echo;echo "\tRestoring profiling outputs"; echo
	$(Q)mkdir -p ../vlt
	$(Q)cp /tmp/*.gc* $(SIM_VLT_DIR)
	$(Q)cp /tmp/*.gc* $(COMMON_BENCH_SYSC_SRC_DIR)

LINT_TOP ?= $(DESIGN_NAME)_top

lint-vlt: $(SIM_VLT_DIR) $(RTL_VERILOG_SRC) $(DUMMY_FILES_FOR_VLT) $(SIM_VLT_DIR)/$(VLT_SCRIPT)
	$(Q)echo; echo "\tLinting design with Verilator"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	verilator -language 1364-2001 --top-module $(LINT_TOP) --lint-only \
	-Mdir .  -I$(COMMON_BENCH_SYSC_INCLUDE_DIR) \
	-I$(COMMON_BENCH_SYSC_SRC_DIR) -f $(SIM_VLT_DIR)/$(VLT_SCRIPT) \
	$(VLT_DEBUG)

# Rule to force generation of the processed orpsoc-defines.h file
processed-verilog-headers-in-c-for-vlt:
	$(Q)$(MAKE) -C $(COMMON_SW_DIR)/lib processed-verilog-headers
# Now copy the file into the Verilated model build path
	$(Q)cp $(COMMON_SW_DIR)/lib/include/orpsoc-defines.h $(SIM_VLT_DIR)
