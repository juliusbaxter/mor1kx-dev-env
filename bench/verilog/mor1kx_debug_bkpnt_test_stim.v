/* 
   Debug interface stimulus for the mor1kx processor.
   This is the verilog stimulus to match the processor software
   for the test called mor1kx-debugtest
 
   Julius Baxter, julius@opencores.org
 
 */

`include "mor1kx-sprs.v"

module mor1kx_debug_bkpnt_test_stim;

   reg [31:0] spr_dat;
   reg [31:0] loop_npc;
   
   // Include the debug utility functions to control the mohor debug unit
   
`define TB_TOP orpsoc_testbench
`define DBG_CTRL `TB_TOP.mohor_debug_control
   `include "mor1kx_mohor_debug_tasks.v"
      
   initial begin
      /* Wait some before beginning - let the processor start up */
      #5000;
      /* Stall the processor */
      reset_everything();
      stall_proc();
      
      /* read an spr */
      read_spr(`OR1K_SPR_SR_ADDR, spr_dat);
      $display("SPR SR: %08h", spr_dat);

      // Store the address of one of the instructions in the loop
      read_npc(loop_npc);
      
      $display("Enabling software breakpoints");
      write_spr(`OR1K_SPR_DSR_ADDR, (1<<13));
      
      /* should kick off the sim */
      write_mem_32(32'd4, 32'h80000000);

      while (1) begin
	 read_npc(spr_dat); $display("NPC is: %08h", spr_dat);
	 unstall_proc();
	 if (spr_dat > loop_npc)
	   /* should finish the sim */
	   write_mem_32(32'd4, 32'h8000000d);
	 
      end

      
     end

endmodule
   