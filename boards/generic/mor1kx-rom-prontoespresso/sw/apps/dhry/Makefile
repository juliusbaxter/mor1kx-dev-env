CUR_DIR=$(shell pwd)

BOARD_ROOT=$(CUR_DIR)/../../..
include $(BOARD_ROOT)/Makefile.inc


BOARD_SW_ROOT=../..
include $(BOARD_SW_ROOT)/Makefile.inc


NUM_RUNS ?= 10

OR32_CFLAGS+= -DNUM_RUNS=$(NUM_RUNS)

%.dis: %.elf
	$(Q)$(OR32_OBJDUMP) -d $< > $@

%.bin: %.elf
	$(Q)$(OR32_OBJCOPY) -O binary $< $@

clean:
	$(Q)rm -f *.elf *.bin *.vmem *.flashin *.dis

