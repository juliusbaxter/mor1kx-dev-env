/*
 mor1kx wrapper for synthesis in ml501 board
 */

`include "mor1kx-defines.v"

module mor1kx_wrapper
  (/*AUTOARG*/
   // Outputs
   iwbm_adr_o, iwbm_stb_o, iwbm_cyc_o, iwbm_sel_o, iwbm_we_o,
   iwbm_cti_o, iwbm_bte_o, iwbm_dat_o, dwbm_adr_o, dwbm_stb_o,
   dwbm_cyc_o, dwbm_sel_o, dwbm_we_o, dwbm_cti_o, dwbm_bte_o,
   dwbm_dat_o, du_dat_o, du_ack_o, du_stall_o,
   // Inputs
   sys_clk_in_p, sys_clk_in_n, rst_n_pad_i, iwbm_err_i, iwbm_ack_i,
   iwbm_dat_i, iwbm_rty_i, dwbm_err_i, dwbm_ack_i, dwbm_dat_i,
   dwbm_rty_i, irq_i, du_addr_i, du_stb_i, du_dat_i, du_we_i,
   du_stall_i
   );

   parameter OPTION_OPERAND_WIDTH = 32;
   
   input sys_clk_in_p,sys_clk_in_n;

   input rst_n_pad_i;

   //   input clk, rst;
   
   output [31:0] iwbm_adr_o;
   output 	 iwbm_stb_o;
   output 	 iwbm_cyc_o;
   output [3:0]  iwbm_sel_o;
   output 	 iwbm_we_o;
   output [2:0]  iwbm_cti_o;
   output [1:0]  iwbm_bte_o;
   output [31:0] iwbm_dat_o;
   input 	 iwbm_err_i;
   input 	 iwbm_ack_i;
   input [31:0]  iwbm_dat_i;
   input 	 iwbm_rty_i;

   output [31:0] dwbm_adr_o;
   output 	 dwbm_stb_o;
   output 	 dwbm_cyc_o;
   output [3:0]  dwbm_sel_o;
   output 	 dwbm_we_o;
   output [2:0]  dwbm_cti_o;
   output [1:0]  dwbm_bte_o;
   output [31:0] dwbm_dat_o;
   input 	 dwbm_err_i;
   input 	 dwbm_ack_i;
   input [31:0]  dwbm_dat_i;
   input 	 dwbm_rty_i;

   input [31:0]  irq_i;

   // Debug interface
   input [15:0]  du_addr_i;
   input 	 du_stb_i;
   input [OPTION_OPERAND_WIDTH-1:0] du_dat_i;
   input 			    du_we_i;
   output [OPTION_OPERAND_WIDTH-1:0] du_dat_o;
   output 			     du_ack_o;
   // Stall control from debug interface
   input 			     du_stall_i;
   output 			     du_stall_o;

   wire 			     clk;
   wire 			     rst;

   /* Dif. input buffer for 200MHz board clock, generate SE 200MHz */
   IBUFGDS_LVPECL_25 sys_clk_in_ibufds
     (
      .O(clk),
      .I(sys_clk_in_p),
      .IB(sys_clk_in_n));
   
   //assign clk = sys_clk_in_p;
   assign rst = !rst_n_pad_i;

   mor1kx
     #(
       .FEATURE_DEBUGUNIT("ENABLED"),
       .OPTION_SHIFTER("BARREL"),
       .FEATURE_SYSCALL("ENABLED"),
       .FEATURE_RANGE("NONE"),
       .FEATURE_FFL1("NONE"),
       .FEATURE_DIVIDER("SERIAL"),
       .FEATURE_MULTIPLIER("THREESTAGE"),
       .FEATURE_SRA("ENABLED"),
       .FEATURE_ROR("ENABLED"),
       
       .OPTION_CPU0("CAPPUCCINO"),
       .FEATURE_INSTRUCTIONCACHE	("ENABLED"),
       .OPTION_ICACHE_BLOCK_WIDTH	(4),
       .OPTION_ICACHE_SET_WIDTH		(9),
       .OPTION_ICACHE_WAYS		(1),
       .OPTION_ICACHE_LIMIT_WIDTH	(32),
       .FEATURE_DATACACHE		("ENABLED"),
       .OPTION_DCACHE_BLOCK_WIDTH	(4),
       .OPTION_DCACHE_SET_WIDTH		(9),
       .OPTION_DCACHE_WAYS		(1),
       .OPTION_DCACHE_LIMIT_WIDTH	(31),

       
       .OPTION_PIC_TRIGGER("LATCHED_LEVEL")
       )
     mor1kx0
     (/*AUTOINST*/
      // Outputs
      .iwbm_adr_o			(iwbm_adr_o[31:0]),
      .iwbm_stb_o			(iwbm_stb_o),
      .iwbm_cyc_o			(iwbm_cyc_o),
      .iwbm_sel_o			(iwbm_sel_o[3:0]),
      .iwbm_we_o			(iwbm_we_o),
      .iwbm_cti_o			(iwbm_cti_o[2:0]),
      .iwbm_bte_o			(iwbm_bte_o[1:0]),
      .iwbm_dat_o			(iwbm_dat_o[31:0]),
      .dwbm_adr_o			(dwbm_adr_o[31:0]),
      .dwbm_stb_o			(dwbm_stb_o),
      .dwbm_cyc_o			(dwbm_cyc_o),
      .dwbm_sel_o			(dwbm_sel_o[3:0]),
      .dwbm_we_o			(dwbm_we_o),
      .dwbm_cti_o			(dwbm_cti_o[2:0]),
      .dwbm_bte_o			(dwbm_bte_o[1:0]),
      .dwbm_dat_o			(dwbm_dat_o[31:0]),
      .du_dat_o				(du_dat_o[OPTION_OPERAND_WIDTH-1:0]),
      .du_ack_o				(du_ack_o),
      .du_stall_o			(du_stall_o),
      // Inputs
      .clk				(clk),
      .rst				(rst),
      .iwbm_err_i			(iwbm_err_i),
      .iwbm_ack_i			(iwbm_ack_i),
      .iwbm_dat_i			(iwbm_dat_i[31:0]),
      .iwbm_rty_i			(iwbm_rty_i),
      .dwbm_err_i			(dwbm_err_i),
      .dwbm_ack_i			(dwbm_ack_i),
      .dwbm_dat_i			(dwbm_dat_i[31:0]),
      .dwbm_rty_i			(dwbm_rty_i),
      .irq_i				(irq_i[31:0]),
      .du_addr_i			(du_addr_i[15:0]),
      .du_stb_i				(du_stb_i),
      .du_dat_i				(du_dat_i[OPTION_OPERAND_WIDTH-1:0]),
      .du_we_i				(du_we_i),
      .du_stall_i			(du_stall_i));

   
endmodule // mor1kx_wrapper

// Local Variables:
// verilog-library-flags:("-y ../../../../../../rtl/verilog/mor1kx")
// End: