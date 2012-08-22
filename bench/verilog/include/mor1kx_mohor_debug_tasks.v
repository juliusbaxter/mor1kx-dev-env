
   task reset_everything;
      begin
	 // Reset TAP, set to DEBUG state
	 `DBG_CTRL.reset_tap();
	 `DBG_CTRL.goto_run_test_idle();
	 `DBG_CTRL.set_instruction(4'b1000);
      end
   endtask
   
   task stall_proc;
      begin
	 `DBG_CTRL.module_select(4'h1, 0);
	 `DBG_CTRL.debug_cpu_wr_ctrl(52'h00000_00000001, "stalling");
      end
   endtask // stall_proc

   task unstall_proc;
      begin
	 `DBG_CTRL.module_select(4'h1, 0);
	 `DBG_CTRL.debug_cpu_wr_ctrl(52'h00000_00000000, "unstalling");
      end
   endtask // stall_proc

   task write_mem_32;
      input [31:0] addr;
      input [31:0] data;
      begin
	 `DBG_CTRL.module_select(4'h0, 0);
	 `DBG_CTRL.wb_write_32(data, addr,3);
      end
   endtask // write_mem_32

   task read_spr;
      input [15:0] spr_addr;
      output [31:0] spr;
      begin
	 `DBG_CTRL.module_select(4'h1, 0);
	 `DBG_CTRL.cpu_read_32(spr, {15'd0, spr_addr}, 3);
      end
   endtask // read_spr

   task write_spr;
      input [15:0] spr_addr;
      input [31:0] dat;
      begin
	 `DBG_CTRL.module_select(4'h1, 0);
	 `DBG_CTRL.cpu_write_32(dat, {15'd0, spr_addr}, 3);
      end
   endtask // write_spr


   task read_npc;
      output [31:0] dat;
      begin
	 read_spr(`OR1K_SPR_NPC_ADDR, dat);
      end
   endtask

   task write_npc;
      input [31:0] dat;
      begin
	 write_spr(`OR1K_SPR_NPC_ADDR, dat);
      end
   endtask // write_npc

   task single_step;
      reg [51:0] stall_poll;
      begin
	 /* set the single step bit of the DMR1 reg */
	 write_spr(`OR1K_SPR_DMR1_ADDR, 1<<22);
	 /* Ensure trap makes CPU stall */
	 write_spr(`OR1K_SPR_DSR_ADDR, 1<<13);
	 unstall_proc();
	 /* wait until the processor is stalled again */
	 `DBG_CTRL.debug_cpu_rd_ctrl(stall_poll);
	 $display("stall: %h",stall_poll[1]); 
	 while (!stall_poll[1]) begin
	   `DBG_CTRL.debug_cpu_rd_ctrl(stall_poll);
	    $display("stall: %h",stall_poll[1]);
	 end
	 /* should be stalled again */
	 /* clear the single step bit of the DMR1 reg */
	 write_spr(`OR1K_SPR_DMR1_ADDR, 0);
	 /* Ensure trap makes CPU stall */
	 write_spr(`OR1K_SPR_DSR_ADDR, 0);
      end
   endtask
