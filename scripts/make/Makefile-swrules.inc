
#
# Software compilation rules used mostly in simulation.
#

# Name of the image the RAM model will attempt to load via Verilog $readmemh
# system function.

# Set PRELOAD_RAM=1 to preload the system memory
ifeq ($(PRELOAD_RAM), 1)
SIM_SW_IMAGE ?=sram.vmem
endif

ifeq ($(SIM_SW_IMAGE),)
SIM_SW_IMAGE ?=flash.in
endif

.PHONY : sw
sw: $(SIM_SW_IMAGE)


flash.in: $(SW_TEST_DIR)/$(TEST).flashin
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)ln -s $< $@

flash16.in: $(SW_TEST_DIR)/$(TEST).flash16
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)ln -s $< $@

ifeq ($(USER_ELF),)
sram.vmem: $(SW_TEST_DIR)/$(TEST).vmem
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)ln -s $< $@
endif

.PHONY: $(SW_TEST_DIR)/$(TEST).flashin
$(SW_TEST_DIR)/$(TEST).flashin:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(SW_TEST_DIR) $(TEST).flashin

.PHONY: $(SW_TEST_DIR)/$(TEST).vmem

# If USER_ELF was specified, then we need a slightly different way of
# generating the VMEM file from it than a usual test
ifeq ($(USER_ELF),)
$(SW_TEST_DIR)/$(TEST).vmem:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(SW_TEST_DIR) $(TEST).vmem
else

ELF_FILE=$(USER_ELF)
ELF_FILE_NOTDIR=$(notdir $(USER_ELF))
ELF_FILE_NOTDIR_BASENAME=$(basename $(ELF_FILE_NOTDIR))

sram.vmem: $(USER_ELF)
	$(Q) echo; echo "\t### Generating VMEM from user ELF ###"; echo;
	$(Q)$(MAKE) -C $(COMMON_SW_DIR)/lib \
	USER_ELF_BIN=`pwd`/$(ELF_FILE_NOTDIR_BASENAME).bin \
	USER_ELF_VMEM=`pwd`/$(ELF_FILE_NOTDIR_BASENAME).vmem \
	gen-user-elf-vmem
	$(Q)cp -v $(ELF_FILE_NOTDIR_BASENAME).vmem $@
endif

.PHONY: $(SW_TEST_DIR)/$(TEST).flash16
$(SW_TEST_DIR)/$(TEST).flash16:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(SW_TEST_DIR) $(TEST).flash16

# Create test software disassembly

sw-dis: $(SW_TEST_DIR)/$(TEST).dis
	$(Q)cp -v $< .

$(SW_TEST_DIR)/$(TEST).dis:
	$(Q)$(MAKE) -C $(SW_TEST_DIR) $(TEST).dis

# Compile ELF and copy it here - useful for running in or1ksim
sw-elf: $(SW_TEST_DIR)/$(TEST).elf
	$(Q)cp -v $< .

$(SW_TEST_DIR)/$(TEST).elf:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(SW_TEST_DIR) $(TEST).elf

#
# Clean rules
#

clean-sim-test-sw:
	$(Q)if [ -e $(SIM_SW_IMAGE) ]; then unlink $(SIM_SW_IMAGE); fi
