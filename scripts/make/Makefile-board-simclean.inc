# Clean rules

clean: clean-sim clean-sim-test-sw clean-bootrom clean-out clean-sw clean-vlt

clean-sim:
	$(Q) echo; echo "\t### Cleaning simulation run directory ###"; echo;
	$(Q)rm -rf *.* lib_* work transcript check-test-log
	$(Q) if [ -e $(VPI_SRC_C_DIR) ]; then $(MAKE) -C $(VPI_SRC_C_DIR) clean; fi

clean-out:
	$(Q)rm -rf $(RTL_SIM_RESULTS_DIR)/*.*

clean-test-defines:
	$(Q)rm -f $(TEST_DEFINES_VLG)

clean-vlt:
	$(Q)rm -rf $(SIM_VLT_DIR)
	$(Q)$(MAKE) -C $(COMMON_BENCH_SYSC_SRC_DIR) -f \
		$(COMMON_BENCH_SYSC_SRC_DIR)/Modules.make clean


distclean: clean