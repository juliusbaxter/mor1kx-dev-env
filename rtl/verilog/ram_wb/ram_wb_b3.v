`include "synthesis-defines.v"
module ram_wb_b3(/*AUTOARG*/
   // Outputs
   wb_ack_o, wb_err_o, wb_rty_o, wb_dat_o,
   // Inputs
   wb_adr_i, wb_bte_i, wb_cti_i, wb_cyc_i, wb_dat_i, wb_sel_i,
   wb_stb_i, wb_we_i, wb_clk_i, wb_rst_i
   );

   parameter dw = 32;
   parameter aw = 32;

   input [aw-1:0]	wb_adr_i;
   input [1:0] 		wb_bte_i;
   input [2:0] 		wb_cti_i;
   input 		wb_cyc_i;
   input [dw-1:0] 	wb_dat_i;
   input [3:0] 		wb_sel_i;
   input 		wb_stb_i;
   input 		wb_we_i;
   
   output 		wb_ack_o;
   output 		wb_err_o;
   output 		wb_rty_o;
   output [dw-1:0] 	wb_dat_o;
   
   input 		wb_clk_i;
   input 		wb_rst_i;

   // Memory parameters
   parameter mem_size_bytes = 32'h0000_5000; // 20KBytes
   parameter mem_adr_width = 15; //(log2(mem_size_bytes));
   
   parameter bytes_per_dw = (dw/8);
   parameter adr_width_for_num_word_bytes = 2; //(log2(bytes_per_dw))
   parameter mem_words = (mem_size_bytes/bytes_per_dw);
   
   // synthesis translate_off
   // synthesis attribute ram_style of mem is block
   reg [dw-1:0] 	mem [ 0 : mem_words-1 ]   /* verilator public */;
   //synthesis translate_on

   // synthesis attribute ram_style of mem0 is block
   // synthesis attribute ram_style of mem1 is block
   // synthesis attribute ram_style of mem2 is block
   // synthesis attribute ram_style of mem3 is block
   reg [(dw/4)-1:0] 	mem0 [ 0 : mem_words-1 ]   /* verilator public */ /* synthesis ram_style = no_rw_check */;
   reg [(dw/4)-1:0] 	mem1 [ 0 : mem_words-1 ]   /* verilator public */ /* synthesis ram_style = no_rw_check */;
   reg [(dw/4)-1:0] 	mem2 [ 0 : mem_words-1 ]   /* verilator public */ /* synthesis ram_style = no_rw_check */;
   reg [(dw/4)-1:0] 	mem3 [ 0 : mem_words-1 ]   /* verilator public */ /* synthesis ram_style = no_rw_check */;

   parameter mem_addr_reg_width = mem_adr_width-adr_width_for_num_word_bytes;
   
   // Register to address internal memory array
   reg [mem_addr_reg_width-1:0] adr;
   
   wire [31:0] 			   wr_data;

   // Register to indicate if the cycle is a Wishbone B3-registered feedback 
   // type access
   reg 				   wb_b3_trans;
   wire 			   wb_b3_trans_start, wb_b3_trans_stop;
   
   reg [2:0] 			   wb_cti_i_r;
   reg [1:0] 			   wb_bte_i_r;
   wire 			   using_burst_adr;
   wire 			   burst_access_wrong_wb_adr;

   // Wire to indicate addressing error
   wire 			   addr_err;   
   
   parameter random_start_delay = 0;
   reg 			random_value = 0;
   reg 			random_start_delay_done;
   reg 			wb_stb_i_r;

   wire 		wb_stb_i_re;
   wire 		gated_wb_stb_i;
   

   assign gated_wb_stb_i = random_start_delay_done ? wb_stb_i : random_value;
      
   always @(posedge wb_clk_i)
     if (wb_rst_i)
	  random_start_delay_done <= !random_start_delay;
     else if (random_start_delay)
       begin
	  if (!wb_stb_i)
	    random_start_delay_done <= 0;
	  if (!random_start_delay_done & wb_stb_i)
	    random_start_delay_done <= random_value;
       end
   
   // Logic to detect if there's a burst access going on
   assign wb_b3_trans_start = ((wb_cti_i == 3'b001)|(wb_cti_i == 3'b010)) & 
			      gated_wb_stb_i & !wb_b3_trans;
   
   assign  wb_b3_trans_stop = ((wb_cti_i == 3'b111) & 
			      gated_wb_stb_i & wb_b3_trans & wb_ack_o) | wb_err_o;
   
   always @(posedge wb_clk_i)
     if (wb_rst_i)
       wb_b3_trans <= 0;
     else if (wb_b3_trans_start)
       wb_b3_trans <= 1;
     else if (wb_b3_trans_stop)
       wb_b3_trans <= 0;

   always @(posedge wb_clk_i)
     wb_bte_i_r <= wb_bte_i;

   // Register it locally
   always @(posedge wb_clk_i)
     wb_cti_i_r <= wb_cti_i;

   assign using_burst_adr = wb_b3_trans;
   
   assign burst_access_wrong_wb_adr = (using_burst_adr & 
				       (adr != wb_adr_i[mem_adr_width-1:2]));

   // Address registering logic
   always@(posedge wb_clk_i)
     if(wb_rst_i)
       adr <= 0;
     else if (using_burst_adr)
       begin
	  if (wb_b3_trans_start)
	    // Kick off burst_adr_counter, this assumes 4-byte words when 
	    // getting address off incoming Wishbone bus address! 
	    // So if dw is no longer 4 bytes, change this!
	    adr <= wb_adr_i[mem_adr_width-1:2];
	  else if ((wb_cti_i_r == 3'b010) & wb_ack_o & wb_b3_trans)
	    // Incrementing burst
	    begin
	       if (wb_bte_i_r == 2'b00) // Linear burst
		 adr <= adr + 1;
	       if (wb_bte_i_r == 2'b01) // 4-beat wrap burst
		 adr[1:0] <= adr[1:0] + 1;
	       if (wb_bte_i_r == 2'b10) // 8-beat wrap burst
		 adr[2:0] <= adr[2:0] + 1;
	       if (wb_bte_i_r == 2'b11) // 16-beat wrap burst
		 adr[3:0] <= adr[3:0] + 1;
	    end // if ((wb_cti_i_r == 3'b010) & wb_ack_o_r)
       end // if (using_burst_adr)
     else if (wb_cyc_i & gated_wb_stb_i)
       adr <= wb_adr_i[mem_adr_width-1:2];

   /* Memory initialisation.
    If not Verilator model, always do load, otherwise only load when called
    from SystemC testbench.
    */
   parameter memory_file = "sram.vmem";
// synthesis translate_off

   integer i;

   task load_byte_rams;
      begin
	$readmemh(memory_file, mem);	
	for(i=0;i<mem_words;i=i+1)
	  begin
	     if (!(mem[i]===32'hxxxxxxxx)) begin
		mem0[i] = mem[i][31:24];
		mem1[i] = mem[i][23:16];
		mem2[i] = mem[i][15:8];
		mem3[i] = mem[i][7:0];
	     end
	  end // initial begin
	$display("%m: Preloaded with %d words",i);
	 
      end
   endtask // load_byte_rams


`ifdef verilator
   
   task do_readmemh;
      // verilator public
      load_byte_rams();
   endtask // do_readmemh
   
`endif
   
   //synthesis translate_on   
  
   initial
     begin

`ifdef XILINX_SYNTHESIS_PRELOAD
	$readmemh("sram0.vmem", mem0);
	$readmemh("sram1.vmem", mem1);
	$readmemh("sram2.vmem", mem2);
	$readmemh("sram3.vmem", mem3);
`endif
	
`ifndef verilator
 `ifndef SYNTHESIS
	load_byte_rams();
 `endif
`endif
	
     end
   
   assign wb_rty_o = 0;

   wire ram_we;
   assign ram_we = wb_we_i & wb_ack_o;

   assign wb_dat_o = {mem0[adr],mem1[adr],mem2[adr],mem3[adr]};
    
   // Write logic
   always @ (posedge wb_clk_i)
     begin
	if (ram_we)
	  begin
	     if (wb_sel_i[3])
	       mem0[adr] <= wb_dat_i[31:24];
	     if (wb_sel_i[2])
	       mem1[adr] <= wb_dat_i[23:16];
	     if (wb_sel_i[1])
	       mem2[adr] <= wb_dat_i[15:8];
	     if (wb_sel_i[0])
	       mem3[adr] <= wb_dat_i[7:0];
	     
	     //mem[adr] <= wr_data;
	  end
     end
   
   // Ack Logic
   reg wb_ack_o_r;

   always @ (posedge wb_clk_i)
     if (wb_rst_i)
       wb_ack_o_r <= 1'b0;
     else if (wb_cyc_i) // We have bus
       begin
	  if (addr_err & gated_wb_stb_i)
	    begin
	       wb_ack_o_r <= 1;
	    end
	  else if (wb_cti_i == 3'b000)
	    begin
	       // Classic cycle acks
	       if (gated_wb_stb_i)
		 begin
		    if (!wb_ack_o_r)
		      wb_ack_o_r <= 1;
		    else
		      wb_ack_o_r <= 0;
		 end
	    end // if (wb_cti_i == 3'b000)
	  else if ((wb_cti_i == 3'b001) | (wb_cti_i == 3'b010))
	    begin
	       // Increment/constant address bursts
	       if (gated_wb_stb_i)
		 wb_ack_o_r <= 1;
	       else
		 wb_ack_o_r <= 0;
	    end
	  else if (wb_cti_i == 3'b111)
	    begin
	       // End of cycle
	       if (!wb_ack_o_r)
		 wb_ack_o_r <= gated_wb_stb_i;
	       else
		 wb_ack_o_r <= 0;
	    end
       end // if (wb_cyc_i)
     else
       wb_ack_o_r <= 0;

   assign wb_ack_o = wb_ack_o_r & 
		     !(burst_access_wrong_wb_adr | addr_err);

   //
   // Error signal generation
   //
   
   // Error when out of bounds of memory - skip top nibble of address in case
   // this is mapped somewhere other than 0x0.
   assign addr_err  = (|wb_adr_i[aw-1-4:mem_adr_width]);  
   
   // OR in other errors here...
   assign wb_err_o =  wb_ack_o_r & 
		      (burst_access_wrong_wb_adr | addr_err);

   //
   // Access functions
   //
   // synthesis translate_off
   // Function to access RAM (for use by Verilator).
   function [31:0] get_mem32;
      // verilator public
      input [aw-1:0] 		addr;
      get_mem32 = {mem0[addr],mem1[addr],mem2[addr],mem3[addr]};
   endfunction // get_mem32   

   // Function to access RAM (for use by Verilator).
   function [7:0] get_mem8;
      // verilator public
      input [aw-1:0] 		addr;
      begin
	 // Big endian mapping.
	 get_mem8 = (addr[1:0]==2'b00) ? mem0[{addr[(mem_addr_reg_width+2)-1:2]}] :
		    (addr[1:0]==2'b01) ? mem1[{addr[(mem_addr_reg_width+2)-1:2]}] :
		    (addr[1:0]==2'b10) ? mem2[{addr[(mem_addr_reg_width+2)-1:2]}] : 
		    mem3[{addr[(mem_addr_reg_width+2)-1:2]}];
	 end
   endfunction // get_mem8   

   // Function to write RAM (for use by Verilator).
   function set_mem32;
      // verilator public
      input [aw-1:0] 		addr;
      input [dw-1:0] 		data;
      begin
	 mem0[addr] = data[31:24];
	 mem1[addr] = data[23:16];
	 mem2[addr] = data[15:8];
	 mem3[addr] = data[7:0];
      end
   endfunction // set_mem32   
   // synthesis translate_on

   // Random ACK negation logic
   generate
      if (random_start_delay)
	begin : lfsr
	   reg [31:0] lfsr;
	   always @(posedge wb_clk_i)
	     if (wb_rst_i)
	       lfsr <= 32'h273e2d4a;
	     else lfsr <= {lfsr[30:0], ~(lfsr[30]^lfsr[6]^lfsr[4]^lfsr[1]^lfsr[0])};
	   always @(posedge wb_clk_i)
	     random_value <= lfsr[26];   
	end
   endgenerate

endmodule // ram_wb_b3

