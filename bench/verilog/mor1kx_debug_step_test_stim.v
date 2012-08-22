/* 
   Debug interface stimulus for the mor1kx processor.
   This is the verilog stimulus to match the processor software
   for the test called mor1kx-debugsteptest
 
   Julius Baxter, julius@opencores.org
 
 */

`include "mor1kx-sprs.v"

/* write this word into address 0x4 in memory to start the
 software test */
`define TEST_START_WORD 32'h80000000
`define TEST_FINISH_WORD 32'h8000000d

module mor1kx_debug_step_test_stim;

   reg [31:0] spr_dat;

   // Define where things are in this testbench
`define TB_TOP orpsoc_testbench
`define DBG_CTRL `TB_TOP.mohor_debug_control
   
   // Include the debug utility functions to control the mohor debug unit
`include "mor1kx_mohor_debug_tasks.v"

   initial begin
      /* Wait some before beginning - let the clocks start and reset released */
      #2000;
      /* Stall the processor */
      reset_everything();
      stall_proc();

      /* software should start now */
      write_mem_32(32'd8, `TEST_START_WORD);

      /* read SR */
      read_spr(`OR1K_SPR_SR_ADDR, spr_dat); $display("SPR SR: %08h", spr_dat);
      /* read NPC */
      read_npc(spr_dat); $display("NPC is: %08h", spr_dat);

      /* the sim will finish now when we run it */
      write_mem_32(32'd4, `TEST_FINISH_WORD);

      /* reset it */
      write_spr(`OR1K_SPR_NPC_ADDR, 32'h0000100);

      /* should finish the sim */
      while (1) begin
	 read_npc(spr_dat); $display("%08t NPC is: %08h", $time, spr_dat);
	 single_step();
      end
   end

endmodule
   