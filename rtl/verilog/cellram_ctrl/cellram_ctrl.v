////////////////////////////////////////////////////////////////// ////
////                                                              //// 
////  Cellular RAM controller                                     //// 
////                                                              //// 
////  Description                                                 //// 
////  See below                                                   //// 
////                                                              //// 
////  To Do:                                                      //// 
////   -                                                          //// 
////                                                              //// 
////  Author(s):                                                  //// 
////      - Julius Baxter, julius@opencores.org                   //// 
////                                                              //// 
////////////////////////////////////////////////////////////////////// 
////                                                              //// 
//// Copyright (C) 2012 Authors and OPENCORES.ORG                 //// 
////                                                              //// 
//// This source file may be used and distributed without         //// 
//// restriction provided that this copyright statement is not    //// 
//// removed from the file and that any derivative work contains  //// 
//// the original copyright notice and the associated disclaimer. //// 
////                                                              //// 
//// This source file is free software; you can redistribute it   //// 
//// and/or modify it under the terms of the GNU Lesser General   //// 
//// Public License as published by the Free Software Foundation; //// 
//// either version 2.1 of the License, or (at your option) any   //// 
//// later version.                                               //// 
////                                                              //// 
//// This source is distributed in the hope that it will be       //// 
//// useful, but WITHOUT ANY WARRANTY; without even the implied   //// 
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //// 
//// PURPOSE.  See the GNU Lesser General Public License for more //// 
//// details.                                                     //// 
////                                                              //// 
//// You should have received a copy of the GNU Lesser General    //// 
//// Public License along with this source; if not, download it   //// 
//// from http://www.gnu.org/copyleft/lesser.html                 //// 
////                                                              ////
////////////////////////////////////////////////////////////////////// 

/*
 Cellular RAM controller with 32-bit Wishbone classic interface
 */

module cellram_ctrl
  (
   wb_clk_i, wb_rst_i,
     
   wb_dat_i, wb_adr_i,
   wb_stb_i, wb_cyc_i,
   wb_we_i, wb_sel_i,
   wb_dat_o, wb_ack_o,
   wb_err_o, wb_rty_o,


   cellram_dq_io,
   cellram_adr_o,
   cellram_adv_n_o,
   cellram_ce_n_o,
   cellram_clk_o,
   cellram_oe_n_o,
   cellram_rst_n_o,
   cellram_wait_i,
   cellram_we_n_o,
   cellram_wp_n_o,
   cellram_cre_o,
   cellram_lb_n_o,
   cellram_ub_n_o
   
  
   );

   parameter cellram_dq_width = 16;
   parameter cellram_adr_width = 23;

   parameter cellram_write_cycles = 4; // wlwh/Tclk = 50ns / 15 ns (66Mhz)
   parameter cellram_read_cycles = 7;  // elqv/Tclk = 95 / 15 ns (66MHz)

   inout [cellram_dq_width-1:0] 	   cellram_dq_io;
   output [cellram_adr_width-1:0] 	   cellram_adr_o;

   output 				   cellram_adv_n_o;
   output 				   cellram_ce_n_o;
   output 				   cellram_clk_o;
   output 				   cellram_oe_n_o;
   output 				   cellram_rst_n_o;
   input 				   cellram_wait_i;
   output 				   cellram_we_n_o;
   output 				   cellram_wp_n_o;
   output 				   cellram_cre_o;
   output 				   cellram_ub_n_o;
   output 				   cellram_lb_n_o;

   input 				   wb_clk_i, wb_rst_i;


   input [31:0] 			   wb_dat_i, wb_adr_i;
   input 				   wb_stb_i, wb_cyc_i,
					   wb_we_i;
   input [3:0] 				   wb_sel_i;
   
   output reg [31:0] 			   wb_dat_o;
   output reg 				   wb_ack_o;
   output 				   wb_err_o, wb_rty_o;

   reg [3:0] 				   wb_state;

   reg 					   long_read;
   reg 					   long_write;   
   reg [4:0] 				   cellram_ctr;

   reg [cellram_dq_width-1:0] 		   cellram_dq_o_r;
   reg [cellram_adr_width-1:0] 		   cellram_adr_o_r;
   reg 					   cellram_oe_n_o_r;
   reg 					   cellram_ce_n_o_r;
   reg 					   cellram_lb_n_o_r, cellram_ub_n_o_r;
   reg 					   cellram_adv_n_o_r;
   reg 					   cellram_we_n_o_r;
   reg 					   cellram_rst_n_o_r;
   reg 					   cellram_cre_o_r;
   
   wire 				   our_cellram_oe;

   assign cellram_ce_n_o = cellram_ce_n_o_r;
   assign cellram_lb_n_o = cellram_lb_n_o_r;
   assign cellram_ub_n_o = cellram_ub_n_o_r;
   assign cellram_clk_o = 0;
   assign cellram_rst_n_o = cellram_rst_n_o_r;
   assign cellram_wp_n_o = 1;
   assign cellram_adv_n_o = cellram_adv_n_o_r;
   assign cellram_dq_io = (our_cellram_oe) ? cellram_dq_o_r : 
			  {cellram_dq_width{1'bz}};
   assign cellram_adr_o = cellram_adr_o_r;
   assign cellram_oe_n_o = cellram_oe_n_o_r;
   assign cellram_we_n_o = cellram_we_n_o_r;

   // Disabled for now
   assign cellram_cre_o = cellram_cre_o_r;
   

`define WB_STATE_IDLE 0
`define WB_STATE_WAIT 1

   assign our_cellram_oe = (wb_state == `WB_STATE_WAIT ||
			    wb_ack_o) & wb_we_i;


   parameter RCR_PAGE_MODE_ENABLE = 23'b000_00_0000000000_1_00_1_0_000;
   reg 					   in_rcr_mode;
   reg [5:0] 				   rcr_mode_state;

   
   
   always @(posedge wb_clk_i)
     if (wb_rst_i)
       begin
	  wb_ack_o <= 0;
	  wb_dat_o <= 0;
	  wb_state <= `WB_STATE_IDLE;
	  cellram_dq_o_r <= 0;
	  cellram_adr_o_r <= 0;
	  cellram_oe_n_o_r <= 1;
	  cellram_we_n_o_r <= 1;
	  cellram_rst_n_o_r <= 0; /* active */
	  cellram_adv_n_o_r <= 1;
	  cellram_ce_n_o_r <= 1;
	  cellram_cre_o_r <= 0;
	  cellram_lb_n_o_r <= 1;
	  cellram_ub_n_o_r <= 1;
	  
	  long_read <= 0;
	  long_write <= 0;
	  cellram_ctr <= 0;

	  in_rcr_mode <= 0;
	  rcr_mode_state <= 0;
	  
	  
       end
     else if (!in_rcr_mode) begin
	// Logic to put the cellram in page mode
	rcr_mode_state <= rcr_mode_state + 1;
	if (rcr_mode_state==0)
	  begin
	     cellram_adr_o_r <= RCR_PAGE_MODE_ENABLE;
	     cellram_cre_o_r <= 1;
	     cellram_ce_n_o_r <= 0;
	     cellram_adv_n_o_r <= 0;
	  end
	if (rcr_mode_state==2)
	  begin
	     cellram_we_n_o_r <= 0;
	  end
	if (rcr_mode_state==(2+cellram_write_cycles))
	  begin
	     cellram_ce_n_o_r <= 1;
	     cellram_we_n_o_r <= 1;
	     cellram_adv_n_o_r <= 1;
	  end
	if (rcr_mode_state==(2+cellram_write_cycles)+1)
	  begin
	     cellram_cre_o_r <= 0;
	  end
	if (rcr_mode_state==(2+cellram_read_cycles))
	  begin
	     
	     cellram_adr_o_r <= 0;
	  end

	// Now read array
	if (rcr_mode_state==(2+cellram_read_cycles)+2)
	  begin
	     cellram_ce_n_o_r <= 0;
	     cellram_oe_n_o_r <= 0;
	     cellram_adv_n_o_r <= 0;
	     cellram_ub_n_o_r <= 0;
	     cellram_lb_n_o_r <= 0;
	  end

	if (rcr_mode_state==(2+2*cellram_read_cycles)+2)
	  begin
	     cellram_ce_n_o_r <= 1;
	     cellram_oe_n_o_r <= 1;
	     // leave adv low cellram_adv_n_o_r <= 1;
	     in_rcr_mode <= 1;
	  end
     end
     else begin
	if (|cellram_ctr)
	  cellram_ctr <= cellram_ctr - 1;
	
	case(wb_state)
	  `WB_STATE_IDLE: begin
	     /* reset some signals to NOP status */
	     wb_ack_o <= 0;
	     cellram_oe_n_o_r <= 1;
	     cellram_ce_n_o_r <= 1;
	     cellram_we_n_o_r <= 1;
	     cellram_rst_n_o_r <= 1;
	     cellram_lb_n_o_r <= 1;
	     cellram_ub_n_o_r <= 1;
	     

	     if (wb_stb_i & wb_cyc_i & !wb_ack_o) begin
		if (!(|wb_sel_i[3:2]) && (|wb_sel_i[1:0]))
		  // Data to access is in second 16-bit word
		  cellram_adr_o_r <=  {wb_adr_i[cellram_adr_width:2],1'b0} + 1;
		else
		  cellram_adr_o_r <= {wb_adr_i[cellram_adr_width:2],1'b0};
		
		wb_state <= `WB_STATE_WAIT;
		if (wb_adr_i[27]) begin
		   /* Reset the flash, no matter the access */
		   cellram_rst_n_o_r <= 0;
		   cellram_ctr <= 5'd16;
		end
		else if (wb_we_i) begin
		   /* load counter with write cycle counter */
		   cellram_ctr <= cellram_write_cycles - 1;
		   /* flash bus write command */
		   cellram_we_n_o_r <= 0;
		   cellram_ce_n_o_r <= 0;
		   cellram_dq_o_r <= (|wb_sel_i[3:2]) ? wb_dat_i[31:16] :
				     wb_dat_i[15:0];
		   cellram_ub_n_o_r <= !(wb_sel_i[3] | wb_sel_i[1]);
		   cellram_lb_n_o_r <= !(wb_sel_i[2] | wb_sel_i[0]);
		   long_write <= &wb_sel_i;
		end
		else begin
		   /* load counter with write cycle counter */
		   cellram_ctr <= cellram_read_cycles - 1;
		   if (&wb_sel_i)
		     long_read <= 1; // Full 32-bit read, 2 read cycles
		   cellram_oe_n_o_r <= 0;
		   cellram_ce_n_o_r <= 0;
		   cellram_lb_n_o_r <= 0;
		   cellram_ub_n_o_r <= 0;
		   
		end // else: !if(wb_we_i)
	     end // if (wb_stb_i & wb_cyc_i)
	     
	  end
	  `WB_STATE_WAIT: begin
	     if (!(|cellram_ctr)) begin
		if (wb_we_i) begin
		   /* write finished */
		   // Another?
		   if (long_write) begin
		      if (!cellram_ce_n_o_r) begin
			 // Just finished first write
			 // Assert this for a cycle before doing the next write
			 cellram_ce_n_o_r <= 1;
			 cellram_we_n_o_r <= 1;
			 cellram_ctr <= 1;
		      end // if (!cellram_ce_n_o_r)
		      else
			begin
			   // Kick off next write
			   cellram_ctr <= cellram_write_cycles - 1;
			   cellram_ce_n_o_r <= 0;
			   cellram_we_n_o_r <= 0;
			   cellram_adr_o_r <= cellram_adr_o_r + 1;
			   cellram_dq_o_r <= wb_dat_i[15:0];
			   long_write <= 0;
			end
		   end
		   else begin
		      wb_ack_o <= 1;
		      wb_state <= `WB_STATE_IDLE;
		      cellram_we_n_o_r <= 1;
		      cellram_ce_n_o_r <= 1;
		   end
		end
		else begin
		   /* read finished */
		   if (!(&wb_sel_i)) /* short or byte read */ begin
		      case (wb_sel_i)
			4'b0001,
			4'b0100:
			  wb_dat_o <= {4{cellram_dq_io[7:0]}};
			4'b1000,
			  4'b0010:
			    wb_dat_o <= {4{cellram_dq_io[15:8]}};
			default:
			  wb_dat_o <= {2{cellram_dq_io}};
		      endcase // case (wb_sel_i)
		      wb_state <= `WB_STATE_IDLE;
		      wb_ack_o <= 1;
		      cellram_oe_n_o_r <= 1;
		   end
		   else if (long_read) begin
		      /* now go on to read next word */
		      wb_dat_o[31:16] <= cellram_dq_io;
		      long_read <= 0;
		      // Next read takes half as long
		      cellram_ctr <= (cellram_read_cycles>>2);
		      cellram_adr_o_r <= cellram_adr_o_r + 1;
		   end
		   else begin
		      /* finished two-part read */
		      wb_dat_o[15:0] <= cellram_dq_io;
		      wb_state <= `WB_STATE_IDLE;
		      wb_ack_o <= 1;
		      cellram_oe_n_o_r <= 1;
		   end
		end
	     end
	  end

	  default:
	    wb_state <= `WB_STATE_IDLE;
	endcase // case (wb_state)
     end // else: !if(wb_rst_i)

endmodule // cfi_ctrl

