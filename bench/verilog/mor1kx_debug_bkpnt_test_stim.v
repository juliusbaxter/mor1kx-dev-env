/* 
   Debug interface stimulus for the mor1kx processor.
   This is the verilog stimulus to match the processor software
   for the test called mor1kx-debugbkpnttest.
 
   That software test has l.trap instructions littered throughout it to
   emulate software with a lot of software breakpoints enabled.
 
   This stimulus will write a l.nop over any trap it hits and resume
   at that address, except if it detects a jump/branch instruction
   immediately previous to the instruction where the trap was (and
   on a pipeline which has delay slots), it will roll the PC back by 4.
 
   Julius Baxter, julius@opencores.org
 
 */

`include "mor1kx-defines.v" // For insn opcodes
`include "mor1kx-sprs.v"

module mor1kx_debug_bkpnt_test_stim;

   reg [31:0] spr_dat;
   reg [31:0] prev_insn;   
   reg [31:0] loop_npc;
   reg 	      stalled;
   reg [31:0] spr_vr2;
   reg 	      has_delay_slot = 1;
   
   
   // Include the debug utility functions to control the mohor debug unit
   
`define TB_TOP orpsoc_testbench
`define DBG_CTRL `TB_TOP.mohor_debug_control
   `include "mor1kx_mohor_debug_tasks.v"

   function is_jump_insn;
      input [31:0] insn;
      reg [5:0]    opc;
      begin
	 if ((|insn)===1'bx)
	   begin
	      // If any bit of the insn is X, then it's uninitialised memory
	      is_jump_insn = 0;
	      //$display("DBG: insn had some Xs in it (%08x)", insn);
	      
	   end
	 else 
	   begin
	      opc = insn[31:26];
	      //$display("DBG: Testing insn opcode: %02x", opc);
	      case (opc)
		`OR1K_OPCODE_J:
		  // Just check it isn't 32'd0 (empty memory) in which case
		  // we don't want to roll back.
		  is_jump_insn = insn==32'd0 ? 0 : 1;
		`OR1K_OPCODE_JAL,
		`OR1K_OPCODE_BNF,
		`OR1K_OPCODE_BF,
		`OR1K_OPCODE_JR,
		`OR1K_OPCODE_JALR:
		  is_jump_insn = 1;
		default:
		  is_jump_insn = 0;
	      endcase // case (opc)
	   end // else: !if((|insn)===1'bx)
      end
   endfunction
   
   
   initial begin
      /* Wait some before beginning - let the processor start up */
      #5000;
      /* Stall the processor */
      reset_everything();
      stall_proc();

      /* Read VR2, get the pipeline ID */
      read_spr(`OR1K_SPR_VR2_ADDR, spr_vr2);
      case(spr_vr2[7:0])
	`MOR1KX_PIPEID_CAPPUCCINO:
	  $display("mor1kx cappuccino pipeline identified (V%01d.%01d)",
		   spr_vr2[23:16],spr_vr2[15:8]);
	`MOR1KX_PIPEID_ESPRESSO:
	  $display("mor1kx espresso pipeline identified (V%01d.%01d)",
		   spr_vr2[23:16],spr_vr2[15:8]);
	`MOR1KX_PIPEID_PRONTOESPRESSO:
	  begin
	     $display("mor1kx pronto espresso pipeline identified (V%01d.%01d)",
		      spr_vr2[23:16],spr_vr2[15:8]);
	     has_delay_slot = 0;
	  end
	default:
	  begin
	     $display("Unable to determine mor1kx pipeline ID");
	     $finish(1);
	  end
      endcase // case (spr_vr2[7:0])
      
      /* read an spr */
      read_spr(`OR1K_SPR_SR_ADDR, spr_dat);
      $display("SPR SR: %08h", spr_dat);

      // Store the address of one of the instructions in the loop
      read_npc(loop_npc);
      
      $display("Enabling software breakpoints");
      write_spr(`OR1K_SPR_DSR_ADDR, (1<<13));
      
      /* should kick off the sim */
      write_mem_32(32'd4, 32'h80000000);

      /* restart processor */
      unstall_proc();
      
      while (1) begin
	 // Check if processor is stalled:
	 get_stall_status(stalled);
	 while(!stalled) begin
	    get_stall_status(stalled);
	 end
	 $display("Detected processor has been stalled");
	 read_spr(`OR1K_SPR_PPC_ADDR, spr_dat);
	 $display("PPC is: %08h", spr_dat);
	 // Check why we stopped
	 read_spr(`OR1K_SPR_DRR_ADDR, spr_dat);
	 $display("DRR is: %08h", spr_dat);
	 if (spr_dat[`OR1K_SPR_DRR_TE])
	   begin
	      // We hit a trap, clear debug reason register
	      write_spr(`OR1K_SPR_DRR_ADDR, 32'd0);
	      // Get PC of address where we stopped
	      read_spr(`OR1K_SPR_PPC_ADDR, spr_dat);
	      // Write a nop there
	      write_mem_32(spr_dat, 32'h15000000);
	      // Test what the preceeding instruction in memory is
	      read_mem_32(spr_dat-4, prev_insn);
	      if (has_delay_slot && is_jump_insn(prev_insn))
		begin
		   // Set NPC back to the preceeding address and unstall
		   spr_dat = spr_dat-4;
		   $display("Detected breakpoint in delay slot- rolling back PC.");
		end
	      write_spr(`OR1K_SPR_NPC_ADDR, spr_dat);
	      $display("Resuming at: %08h", spr_dat);
	      //read_npc(spr_dat); $display("NPC is: %08h", spr_dat);
	      unstall_proc();

	      /* software will read this address to check what was 
	       written here to indicate we correctly got out of the 
	       initial waiting loop */
	      write_mem_32(32'd4, 32'h8000000d);
	      
	   end
	 
      end

      
     end

endmodule
   