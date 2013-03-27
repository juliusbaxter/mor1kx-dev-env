#
# File to do some basic hookup with the gcc regression suite
# and allow the user to run through each test
#
# Enable this by running GCC_TESTS=1
#
# This relies on having a bare-metal tool chain working.
# 
# The path containing the gcc source directory must be passed as GCC_SRC
# eg. make vlt-tests GCC_TESTS=1 GCC_SRC=~/git/or1k-gcc
#
# If the tests were run until a particular failure, the tests can be restarted
# from that particular one by passing GCC_C_TESTS_START_AT
# eg. GCC_C_TESTS_START_AT=920501-6
#
# Skip any tests known to be bad by passing GCC_C_TORTURE_TESTS_SKIP
# eg. GCC_C_TORTURE_TESTS_SKIP="980709-1 990413-2"


ifndef GCC_SRC
$(error If running with GCC_TESTS=1 you must also set the path to the GCC\
sources with GCC_SRC)
endif

# A list of stuff to skip which we maintain in this file
HARDCODED_SKIP_LIST += 20030125-1 #this is a compiler test really, which doesnt work when we use -lm
HARDCODED_SKIP_LIST += 990413-2 #Has volatile asm stuff which isn't appropriate
HARDCODED_SKIP_LIST += eeprof-1 #Relies on some profiling stuff which we don't have
HARDCODED_SKIP_LIST += execute #this is the name of a .exp file which somehow makes it through
HARDCODED_SKIP_LIST += loop-2f loop-2g # relies on some OS stuff like <sys/mman.h>
HARDCODED_SKIP_LIST += pr47237 # looks like we're failing some builtin apply thing...
HARDCODED_SKIP_LIST += 920612-1 920711-1 pr23047 # These fail with -O2 (it precalculates what the called function does and gets it wrong, causing the test to fail by default - CPU appears to execute properly but test still fails?!)

# Make a list of the tests
GCC_C_TORTURE_TESTS_DIR=$(GCC_SRC)/gcc/testsuite/gcc.c-torture/execute
#GCC_C_TORTURE_TESTS=$(shell find $(GCC_C_TORTURE_TESTS_DIR) -maxdepth 1 -type f )
GCC_C_TORTURE_TESTS=$(shell  ls $(GCC_C_TORTURE_TESTS_DIR) | grep \.c)
#$(warning got the following tests: $(GCC_C_TORTURE_TESTS))
GCC_C_TORTURE_TESTS_BASENAME=$(basename $(GCC_C_TORTURE_TESTS))
#$(warning got the following tests: $(GCC_C_TORTURE_TESTS_BASENAME))
GCC_C_TORTURE_TESTS_NAMES_WITHOUT_SUFFIX=$(patsubst %.c, %, $(GCC_C_TORTURE_TESTS_BASENAME) )
# Now filter out any we want to skip
GCC_C_TORTURE_TESTS_NAMES=$(filter-out $(GCC_C_TORTURE_TESTS_SKIP) $(HARDCODED_SKIP_LIST), $(GCC_C_TORTURE_TESTS_NAMES_WITHOUT_SUFFIX))

# Override the tests lists with the gcc regression tests

TESTS= $(GCC_C_TORTURE_TESTS_NAMES)

# If we were asked to start with a particular test
ifneq ($(GCC_C_TESTS_START_AT), )

ifeq ( , $(findstring $(GCC_C_TESTS_START_AT),$(GCC_C_TORTURE_TESTS_NAMES)))
$(error Asked to start at GCC test $(GCC_C_TESTS_START_AT) but it doesnt exist)
endif

GCC_C_TORTURE_TESTS_LIST_STARTING_AT=$(shell seen=0;for t in $(GCC_C_TORTURE_TESTS_NAMES); do if [ $$seen -eq 1 ]; then echo $$t; fi; if [ $$t = $(GCC_C_TESTS_START_AT) ]; then seen=1; echo $$t; fi; done)

$(echo Starting GCC tests at $(GCC_C_TESTS_START_AT))

TESTS=$(GCC_C_TORTURE_TESTS_LIST_STARTING_AT)

endif

print-gccsw-tests:
	echo $(TESTS) 

# Compile all the gcc software under out
SW_BUILD_DIR=../out/gcc-sw-compdir

$(SW_BUILD_DIR):
	mkdir -p $@


flash.in: $(SW_BUILD_DIR) $(SW_BUILD_DIR)/$(TEST).flashin
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)if [ -e $@ ]; then rm $@; fi
	$(Q)ln -s $(SW_BUILD_DIR)/$(TEST).flashin $@

flash16.in: $(SW_BUILD_DIR) $(SW_BUILD_DIR)/$(TEST).flash16
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)ln -s $(SW_BUILD_DIR)/$(TEST).flash16 $@

sram.vmem: $(SW_BUILD_DIR) $(SW_BUILD_DIR)/$(TEST).vmem
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)ln -s $(SW_BUILD_DIR)/$(TEST).vmem  $@


$(SW_BUILD_DIR)/%.flashin: $(SW_BUILD_DIR)/%.bin $(SW_UTILS_BIN2VMEM)
	$(SW_UTILS_BIN2VMEM) $< 1  -size_word -pad $(HEX_IMAGE_PADDING) > $@

$(SW_BUILD_DIR)/%.vmem: $(SW_BUILD_DIR)/%.bin $(SW_UTILS_BIN2VMEM)
	$(Q)$(SW_UTILS_BIN2VMEM) $< > $@

$(SW_BUILD_DIR)/%.flash16: $(SW_BUILD_DIR)/%.bin $(SW_UTILS_BIN2VMEM)
	$(Q)$(SW_UTILS_BIN2VMEM) $< -bpw=2 > $@


OR32_TOOL_PREFIX ?=or1k-elf-

OR32_LD=$(OR32_TOOL_PREFIX)ld
OR32_AS=$(OR32_TOOL_PREFIX)as
OR32_CC=$(OR32_TOOL_PREFIX)gcc
OR32_AR=$(OR32_TOOL_PREFIX)ar
OR32_RANLIB=$(OR32_TOOL_PREFIX)ranlib
OR32_OBJDUMP=$(OR32_TOOL_PREFIX)objdump
OR32_OBJCOPY=$(OR32_TOOL_PREFIX)objcopy

$(SW_BUILD_DIR)/%.bin: $(SW_BUILD_DIR)/%.elf
	$(OR32_OBJCOPY) $< -O binary $@
	$(OR32_OBJDUMP) -d $< > $(SW_BUILD_DIR)/$*.dis

#Now rules for building the elf based 
# Have -lm (link in the maths library) for code requiring the pow() function
# -O2 is a pretty common level of optimisation to use
$(SW_BUILD_DIR)/%.elf: $(GCC_C_TORTURE_TESTS_DIR)/%.c
	$(OR32_CC) -O2 $< $(MARCH_FLAGS) $(BOARD_C_FLAGS) -o $@ -lm

SW_UTILS_DIR=$(PROJECT_ROOT)/sw/utils
SW_UTILS_BIN2VMEM=$(SW_UTILS_DIR)/bin2vmem
$(SW_UTILS_BIN2VMEM):
	$(Q)$(MAKE) -C $(SW_UTILS_DIR) bin2vmem

clean-sim-test-sw:
	rm -rfv $(SW_BUILD_DIR)

