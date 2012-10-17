//////////////////////////////////////////////////////////////////////
///                                                               //// 
/// ORPSoC top for Nexys3 board                                   ////
///                                                               ////
/// Instantiates modules, depending on ORPSoC defines file        ////
///                                                               ////
/// Julius Baxter, julius@opencores.org                           ////
///                                                               ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009, 2010, 2012 Authors and OPENCORES.ORG     ////
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
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "orpsoc-defines.v"
`include "synthesis-defines.v"
module orpsoc_top
  ( 
`ifdef JTAG_DEBUG    
    tdo_pad_o, tms_pad_i, tck_pad_i, tdi_pad_i,
`endif
`ifdef CELLRAM
    cellram_dq_io, cellram_adr_o, cellram_adv_n_o, cellram_ce_n_o,
    cellram_clk_o, cellram_oe_n_o,  cellram_wait_i,
    cellram_we_n_o, cellram_cre_o, cellram_lb_n_o, cellram_ub_n_o,
`endif    
`ifdef UART0
    uart0_srx_pad_i, uart0_stx_pad_o,
`endif
`ifdef SPI0
    spi0_mosi_o, spi0_ss_o,/* spi0_sck_o, spi0_miso_i,via STARTUP_VIRTEX5*/
`endif    
`ifdef I2C0
    i2c0_sda_io, i2c0_scl_io,
`endif    
`ifdef I2C1
    i2c1_sda_io, i2c1_scl_io,
`endif    
`ifdef GPIO0
    gpio0_io,
`endif
  
`ifdef ETH0
    eth0_tx_clk, eth0_tx_data, eth0_tx_en, eth0_tx_er,   
    eth0_rx_clk, eth0_rx_data, eth0_dv, eth0_rx_er,   
    eth0_col, eth0_crs,
    eth0_mdc_pad_o, eth0_md_pad_io,
 `ifdef ETH0_PHY_RST
    eth0_rst_n_o,
 `endif
`endif

    leds, switches,
  
    sys_clk_in,

    rst_i  

    );

`include "orpsoc-params.v"   

   input sys_clk_in;
   input rst_i;
   
`ifdef JTAG_DEBUG    
   output tdo_pad_o;
   input  tms_pad_i;
   input  tck_pad_i;
   input  tdi_pad_i;
`endif
`ifdef CELLRAM
   inout [15:0]    cellram_dq_io;
   output [22:0]    cellram_adr_o;
   output 	    cellram_adv_n_o;
   output 	    cellram_ce_n_o;
   output 	    cellram_clk_o;
   output 	    cellram_oe_n_o;
   input 	    cellram_wait_i;
   output 	    cellram_we_n_o;
   output 	    cellram_cre_o;
   output           cellram_ub_n_o;
   output           cellram_lb_n_o;
`endif   
`ifdef UART0
   input 	 uart0_srx_pad_i;
   output 	 uart0_stx_pad_o;
   // Duplicates of the UART signals, this time to the USB debug cable
   //input 	 uart0_srx_expheader_pad_i;
   //output 	 uart0_stx_expheader_pad_o;
`endif
`ifdef SPI0
   output 	 spi0_mosi_o;
  output [spi0_ss_width-1:0] spi0_ss_o;
`endif
`ifdef I2C0
   inout 		      i2c0_sda_io, i2c0_scl_io;
`endif   
`ifdef I2C1
   inout 		      i2c1_sda_io, i2c1_scl_io;
`endif   
`ifdef GPIO0
   inout [gpio0_io_width-1:0] gpio0_io;   
`endif 
`ifdef ETH0
   input 		      eth0_tx_clk;
   output [3:0] 	      eth0_tx_data;
   output 		      eth0_tx_en;
   output 		      eth0_tx_er;
   input 		      eth0_rx_clk;
   input [3:0] 		      eth0_rx_data;
   input 		      eth0_dv;
   input 		      eth0_rx_er;
   input 		      eth0_col;
   input 		      eth0_crs;
   output 		      eth0_mdc_pad_o;
   inout 		      eth0_md_pad_io;
 `ifdef ETH0_PHY_RST
   output 		      eth0_rst_n_o;
 `endif
`endif //  `ifdef ETH0

   output reg [7:0] 	      leds;
   input [7:0] 		      switches;

   
   ////////////////////////////////////////////////////////////////////////
   //
   // Clock and reset generation module
   // 
   ////////////////////////////////////////////////////////////////////////

   //
   // Wires
   //
   wire 		      wb_clk, wb_rst;
   wire 		      dbg_tck;

   
   clkgen clkgen0
     (
      .sys_clk_in              (sys_clk_in),

      .wb_clk_o                  (wb_clk),
      .wb_rst_o                  (wb_rst),

`ifdef JTAG_DEBUG
      .tck_pad_i                 (tck_pad_i),
      .dbg_tck_o                 (dbg_tck),
`endif
      // Asynchronous active low reset
      .rst_i                    (rst_i)
      );

   
   ////////////////////////////////////////////////////////////////////////
   //
   // Arbiter
   // 
   ////////////////////////////////////////////////////////////////////////
   
   // Wire naming convention:
   // First: wishbone master or slave (wbm/wbs)
   // Second: Which bus it's on instruction or data (i/d)
   // Third: Between which module and the arbiter the wires are
   // Fourth: Signal name
   // Fifth: Direction relative to module (not bus/arbiter!)
   //        ie. wbm_d_or12_adr_o is address OUT from the or1200

   // OR1200 instruction bus wires
   wire [wb_aw-1:0] 	      wbm_i_or12_adr_o;
   wire [wb_dw-1:0] 	      wbm_i_or12_dat_o;
   wire [3:0] 		      wbm_i_or12_sel_o;
   wire 		      wbm_i_or12_we_o;
   wire 		      wbm_i_or12_cyc_o;
   wire 		      wbm_i_or12_stb_o;
   wire [2:0] 		      wbm_i_or12_cti_o;
   wire [1:0] 		      wbm_i_or12_bte_o;
   
   wire [wb_dw-1:0] 	      wbm_i_or12_dat_i;   
   wire 		      wbm_i_or12_ack_i;
   wire 		      wbm_i_or12_err_i;
   wire 		      wbm_i_or12_rty_i;

   // OR1200 data bus wires   
   wire [wb_aw-1:0] 	      wbm_d_or12_adr_o;
   wire [wb_dw-1:0] 	      wbm_d_or12_dat_o;
   wire [3:0] 		      wbm_d_or12_sel_o;
   wire 		      wbm_d_or12_we_o;
   wire 		      wbm_d_or12_cyc_o;
   wire 		      wbm_d_or12_stb_o;
   wire [2:0] 		      wbm_d_or12_cti_o;
   wire [1:0] 		      wbm_d_or12_bte_o;
   
   wire [wb_dw-1:0] 	      wbm_d_or12_dat_i;   
   wire 		      wbm_d_or12_ack_i;
   wire 		      wbm_d_or12_err_i;
   wire 		      wbm_d_or12_rty_i;   

   // Debug interface bus wires   
   wire [wb_aw-1:0] 	      wbm_d_dbg_adr_o;
   wire [wb_dw-1:0] 	      wbm_d_dbg_dat_o;
   wire [3:0] 		      wbm_d_dbg_sel_o;
   wire 		      wbm_d_dbg_we_o;
   wire 		      wbm_d_dbg_cyc_o;
   wire 		      wbm_d_dbg_stb_o;
   wire [2:0] 		      wbm_d_dbg_cti_o;
   wire [1:0] 		      wbm_d_dbg_bte_o;
   
   wire [wb_dw-1:0] 	      wbm_d_dbg_dat_i;   
   wire 		      wbm_d_dbg_ack_i;
   wire 		      wbm_d_dbg_err_i;
   wire 		      wbm_d_dbg_rty_i;

   // Byte bus bridge master signals
   wire [wb_aw-1:0] 	      wbm_b_d_adr_o;
   wire [wb_dw-1:0] 	      wbm_b_d_dat_o;
   wire [3:0] 		      wbm_b_d_sel_o;
   wire 		      wbm_b_d_we_o;
   wire 		      wbm_b_d_cyc_o;
   wire 		      wbm_b_d_stb_o;
   wire [2:0] 		      wbm_b_d_cti_o;
   wire [1:0] 		      wbm_b_d_bte_o;
   
   wire [wb_dw-1:0] 	      wbm_b_d_dat_i;   
   wire 		      wbm_b_d_ack_i;
   wire 		      wbm_b_d_err_i;
   wire 		      wbm_b_d_rty_i;   

   // Instruction bus slave wires //
   
   // rom0 instruction bus wires
   wire [31:0] 		      wbs_i_rom0_adr_i;
   wire [wbs_i_rom0_data_width-1:0] wbs_i_rom0_dat_i;
   wire [3:0] 			    wbs_i_rom0_sel_i;
   wire 			    wbs_i_rom0_we_i;
   wire 			    wbs_i_rom0_cyc_i;
   wire 			    wbs_i_rom0_stb_i;
   wire [2:0] 			    wbs_i_rom0_cti_i;
   wire [1:0] 			    wbs_i_rom0_bte_i;   
   wire [wbs_i_rom0_data_width-1:0] wbs_i_rom0_dat_o;   
   wire 			    wbs_i_rom0_ack_o;
   wire 			    wbs_i_rom0_err_o;
   wire 			    wbs_i_rom0_rty_o;   

   // mc0 instruction bus wires
   wire [31:0] 			    wbs_i_mc0_adr_i;
   wire [wbs_i_mc0_data_width-1:0]  wbs_i_mc0_dat_i;
   wire [3:0] 			    wbs_i_mc0_sel_i;
   wire 			    wbs_i_mc0_we_i;
   wire 			    wbs_i_mc0_cyc_i;
   wire 			    wbs_i_mc0_stb_i;
   wire [2:0] 			    wbs_i_mc0_cti_i;
   wire [1:0] 			    wbs_i_mc0_bte_i;   
   wire [wbs_i_mc0_data_width-1:0]  wbs_i_mc0_dat_o;   
   wire 			    wbs_i_mc0_ack_o;
   wire 			    wbs_i_mc0_err_o;
   wire 			    wbs_i_mc0_rty_o;   

   // flash instruction bus wires
   wire [31:0] 			    wbs_i_cellram_adr_i;
   wire [wbs_i_cellram_data_width-1:0] wbs_i_cellram_dat_i;
   wire [3:0] 			     wbs_i_cellram_sel_i;
   wire 			     wbs_i_cellram_we_i;
   wire 			     wbs_i_cellram_cyc_i;
   wire 			     wbs_i_cellram_stb_i;
   wire [2:0] 			     wbs_i_cellram_cti_i;
   wire [1:0] 			     wbs_i_cellram_bte_i;   
   wire [wbs_i_cellram_data_width-1:0] wbs_i_cellram_dat_o;   
   wire 			     wbs_i_cellram_ack_o;
   wire 			     wbs_i_cellram_err_o;
   wire 			     wbs_i_cellram_rty_o;   
   
   // Data bus slave wires //
   
   // mc0 data bus wires
   wire [31:0] 			    wbs_d_mc0_adr_i;
   wire [wbs_d_mc0_data_width-1:0]  wbs_d_mc0_dat_i;
   wire [3:0] 			    wbs_d_mc0_sel_i;
   wire 			    wbs_d_mc0_we_i;
   wire 			    wbs_d_mc0_cyc_i;
   wire 			    wbs_d_mc0_stb_i;
   wire [2:0] 			    wbs_d_mc0_cti_i;
   wire [1:0] 			    wbs_d_mc0_bte_i;   
   wire [wbs_d_mc0_data_width-1:0]  wbs_d_mc0_dat_o;   
   wire 			    wbs_d_mc0_ack_o;
   wire 			    wbs_d_mc0_err_o;
   wire 			    wbs_d_mc0_rty_o;
   
   // i2c0 wires
   wire [31:0] 			    wbs_d_i2c0_adr_i;
   wire [wbs_d_i2c0_data_width-1:0] wbs_d_i2c0_dat_i;
   wire [3:0] 			    wbs_d_i2c0_sel_i;
   wire 			    wbs_d_i2c0_we_i;
   wire 			    wbs_d_i2c0_cyc_i;
   wire 			    wbs_d_i2c0_stb_i;
   wire [2:0] 			    wbs_d_i2c0_cti_i;
   wire [1:0] 			    wbs_d_i2c0_bte_i;   
   wire [wbs_d_i2c0_data_width-1:0] wbs_d_i2c0_dat_o;   
   wire 			    wbs_d_i2c0_ack_o;
   wire 			    wbs_d_i2c0_err_o;
   wire 			    wbs_d_i2c0_rty_o;   

   // i2c1 wires
   wire [31:0] 			    wbs_d_i2c1_adr_i;
   wire [wbs_d_i2c1_data_width-1:0] wbs_d_i2c1_dat_i;
   wire [3:0] 			    wbs_d_i2c1_sel_i;
   wire 			    wbs_d_i2c1_we_i;
   wire 			    wbs_d_i2c1_cyc_i;
   wire 			    wbs_d_i2c1_stb_i;
   wire [2:0] 			    wbs_d_i2c1_cti_i;
   wire [1:0] 			    wbs_d_i2c1_bte_i;   
   wire [wbs_d_i2c1_data_width-1:0] wbs_d_i2c1_dat_o;   
   wire 			    wbs_d_i2c1_ack_o;
   wire 			    wbs_d_i2c1_err_o;
   wire 			    wbs_d_i2c1_rty_o;
   
   // spi0 wires
   wire [31:0] 			    wbs_d_spi0_adr_i;
   wire [wbs_d_spi0_data_width-1:0] wbs_d_spi0_dat_i;
   wire [3:0] 			    wbs_d_spi0_sel_i;
   wire 			    wbs_d_spi0_we_i;
   wire 			    wbs_d_spi0_cyc_i;
   wire 			    wbs_d_spi0_stb_i;
   wire [2:0] 			    wbs_d_spi0_cti_i;
   wire [1:0] 			    wbs_d_spi0_bte_i;   
   wire [wbs_d_spi0_data_width-1:0] wbs_d_spi0_dat_o;   
   wire 			    wbs_d_spi0_ack_o;
   wire 			    wbs_d_spi0_err_o;
   wire 			    wbs_d_spi0_rty_o;   

   // uart0 wires
   wire [31:0] 			     wbs_d_uart0_adr_i;
   wire [wbs_d_uart0_data_width-1:0] wbs_d_uart0_dat_i;
   wire [3:0] 			     wbs_d_uart0_sel_i;
   wire 			     wbs_d_uart0_we_i;
   wire 			     wbs_d_uart0_cyc_i;
   wire 			     wbs_d_uart0_stb_i;
   wire [2:0] 			     wbs_d_uart0_cti_i;
   wire [1:0] 			     wbs_d_uart0_bte_i;   
   wire [wbs_d_uart0_data_width-1:0] wbs_d_uart0_dat_o;   
   wire 			     wbs_d_uart0_ack_o;
   wire 			     wbs_d_uart0_err_o;
   wire 			     wbs_d_uart0_rty_o;   
   
   // gpio0 wires
   wire [31:0] 			     wbs_d_gpio0_adr_i;
   wire [wbs_d_gpio0_data_width-1:0] wbs_d_gpio0_dat_i;
   wire [3:0] 			     wbs_d_gpio0_sel_i;
   wire 			     wbs_d_gpio0_we_i;
   wire 			     wbs_d_gpio0_cyc_i;
   wire 			     wbs_d_gpio0_stb_i;
   wire [2:0] 			     wbs_d_gpio0_cti_i;
   wire [1:0] 			     wbs_d_gpio0_bte_i;   
   wire [wbs_d_gpio0_data_width-1:0] wbs_d_gpio0_dat_o;   
   wire 			     wbs_d_gpio0_ack_o;
   wire 			     wbs_d_gpio0_err_o;
   wire 			     wbs_d_gpio0_rty_o;

   // eth0 slave wires
   wire [31:0] 				  wbs_d_eth0_adr_i;
   wire [wbs_d_eth0_data_width-1:0] 	  wbs_d_eth0_dat_i;
   wire [3:0] 				  wbs_d_eth0_sel_i;
   wire 				  wbs_d_eth0_we_i;
   wire 				  wbs_d_eth0_cyc_i;
   wire 				  wbs_d_eth0_stb_i;
   wire [2:0] 				  wbs_d_eth0_cti_i;
   wire [1:0] 				  wbs_d_eth0_bte_i;   
   wire [wbs_d_eth0_data_width-1:0] 	  wbs_d_eth0_dat_o;   
   wire 				  wbs_d_eth0_ack_o;
   wire 				  wbs_d_eth0_err_o;
   wire 				  wbs_d_eth0_rty_o;

   // eth0 master wires
   wire [wbm_eth0_addr_width-1:0] 	  wbm_eth0_adr_o;
   wire [wbm_eth0_data_width-1:0] 	  wbm_eth0_dat_o;
   wire [3:0] 				  wbm_eth0_sel_o;
   wire 				  wbm_eth0_we_o;
   wire 				  wbm_eth0_cyc_o;
   wire 				  wbm_eth0_stb_o;
   wire [2:0] 				  wbm_eth0_cti_o;
   wire [1:0] 				  wbm_eth0_bte_o;
   wire [wbm_eth0_data_width-1:0]         wbm_eth0_dat_i;
   wire 				  wbm_eth0_ack_i;
   wire 				  wbm_eth0_err_i;
   wire 				  wbm_eth0_rty_i;

   // flash slave wires
   wire [31:0] 				  wbs_d_cellram_adr_i;
   wire [wbs_d_cellram_data_width-1:0] 	  wbs_d_cellram_dat_i;
   wire [3:0] 				  wbs_d_cellram_sel_i;
   wire 				  wbs_d_cellram_we_i;
   wire 				  wbs_d_cellram_cyc_i;
   wire 				  wbs_d_cellram_stb_i;
   wire [2:0] 				  wbs_d_cellram_cti_i;
   wire [1:0] 				  wbs_d_cellram_bte_i;   
   wire [wbs_d_cellram_data_width-1:0] 	  wbs_d_cellram_dat_o;   
   wire 				  wbs_d_cellram_ack_o;
   wire 				  wbs_d_cellram_err_o;
   wire 				  wbs_d_cellram_rty_o;
   


   //
   // Wishbone instruction bus arbiter
   //
   
   arbiter_ibus
     #(
       .internal_sram_mem_span	(internal_sram_mem_span),
       .wb_addr_match_width	(ibus_arb_addr_match_width),
       .slave0_adr		(ibus_arb_slave0_adr), // flash ROM
       .slave1_adr		(ibus_arb_slave1_adr), // main memory
       .slave2_adr		(ibus_arb_slave2_adr) // cellular RAM
       )
     arbiter_ibus0
     (
      // Instruction Bus Master
      // Inputs to arbiter from master
      .wbm_adr_o			(wbm_i_or12_adr_o),
      .wbm_dat_o			(wbm_i_or12_dat_o),
      .wbm_sel_o			(wbm_i_or12_sel_o),
      .wbm_we_o				(wbm_i_or12_we_o),
      .wbm_cyc_o			(wbm_i_or12_cyc_o),
      .wbm_stb_o			(wbm_i_or12_stb_o),
      .wbm_cti_o			(wbm_i_or12_cti_o),
      .wbm_bte_o			(wbm_i_or12_bte_o),
      // Outputs to master from arbiter
      .wbm_dat_i			(wbm_i_or12_dat_i),
      .wbm_ack_i			(wbm_i_or12_ack_i),
      .wbm_err_i			(wbm_i_or12_err_i),
      .wbm_rty_i			(wbm_i_or12_rty_i),
      
      // Slave 0
      // Inputs to slave from arbiter
      .wbs0_adr_i			(wbs_i_rom0_adr_i),
      .wbs0_dat_i			(wbs_i_rom0_dat_i),
      .wbs0_sel_i			(wbs_i_rom0_sel_i),
      .wbs0_we_i			(wbs_i_rom0_we_i),
      .wbs0_cyc_i			(wbs_i_rom0_cyc_i),
      .wbs0_stb_i			(wbs_i_rom0_stb_i),
      .wbs0_cti_i			(wbs_i_rom0_cti_i),
      .wbs0_bte_i			(wbs_i_rom0_bte_i),
      // Outputs from slave to arbiter      
      .wbs0_dat_o			(wbs_i_rom0_dat_o),
      .wbs0_ack_o			(wbs_i_rom0_ack_o),
      .wbs0_err_o			(wbs_i_rom0_err_o),
      .wbs0_rty_o			(wbs_i_rom0_rty_o),

      // Slave 1
      // Inputs to slave from arbiter
      .wbs1_adr_i			(wbs_i_mc0_adr_i),
      .wbs1_dat_i			(wbs_i_mc0_dat_i),
      .wbs1_sel_i			(wbs_i_mc0_sel_i),
      .wbs1_we_i			(wbs_i_mc0_we_i),
      .wbs1_cyc_i			(wbs_i_mc0_cyc_i),
      .wbs1_stb_i			(wbs_i_mc0_stb_i),
      .wbs1_cti_i			(wbs_i_mc0_cti_i),
      .wbs1_bte_i			(wbs_i_mc0_bte_i),
      // Outputs from slave to arbiter
      .wbs1_dat_o			(wbs_i_mc0_dat_o),
      .wbs1_ack_o			(wbs_i_mc0_ack_o),
      .wbs1_err_o			(wbs_i_mc0_err_o),
      .wbs1_rty_o			(wbs_i_mc0_rty_o),

      // Slave 2
      // Inputs to slave from arbiter
      .wbs2_adr_i			(wbs_i_cellram_adr_i),
      .wbs2_dat_i			(wbs_i_cellram_dat_i),
      .wbs2_sel_i			(wbs_i_cellram_sel_i),
      .wbs2_we_i			(wbs_i_cellram_we_i),
      .wbs2_cyc_i			(wbs_i_cellram_cyc_i),
      .wbs2_stb_i			(wbs_i_cellram_stb_i),
      .wbs2_cti_i			(wbs_i_cellram_cti_i),
      .wbs2_bte_i			(wbs_i_cellram_bte_i),
      // Outputs from slave to arbiter
      .wbs2_dat_o			(wbs_i_cellram_dat_o),
      .wbs2_ack_o			(wbs_i_cellram_ack_o),
      .wbs2_err_o			(wbs_i_cellram_err_o),
      .wbs2_rty_o			(wbs_i_cellram_rty_o),

      // Clock, reset inputs
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst));

   //
   // Wishbone data bus arbiter
   //
   
   arbiter_dbus
     #(
       // These settings are from top level params file
       .wb_addr_match_width	(dbus_arb_wb_addr_match_width),
       .wb_num_slaves		(dbus_arb_wb_num_slaves),
       .slave0_adr		(dbus_arb_slave0_adr),
       .slave1_adr		(dbus_arb_slave1_adr),
       .slave2_adr		(dbus_arb_slave2_adr),
       .internal_sram_mem_span	(internal_sram_mem_span)
       )

arbiter_dbus0
     (
      // Master 0
      // Inputs to arbiter from master
      .wbm0_adr_o			(wbm_d_or12_adr_o),
      .wbm0_dat_o			(wbm_d_or12_dat_o),
      .wbm0_sel_o			(wbm_d_or12_sel_o),
      .wbm0_we_o			(wbm_d_or12_we_o),
      .wbm0_cyc_o			(wbm_d_or12_cyc_o),
      .wbm0_stb_o			(wbm_d_or12_stb_o),
      .wbm0_cti_o			(wbm_d_or12_cti_o),
      .wbm0_bte_o			(wbm_d_or12_bte_o),
      // Outputs to master from arbiter
      .wbm0_dat_i			(wbm_d_or12_dat_i),
      .wbm0_ack_i			(wbm_d_or12_ack_i),
      .wbm0_err_i			(wbm_d_or12_err_i),
      .wbm0_rty_i			(wbm_d_or12_rty_i),

      // Master 0
      // Inputs to arbiter from master
      .wbm1_adr_o			(wbm_d_dbg_adr_o),
      .wbm1_dat_o			(wbm_d_dbg_dat_o),
      .wbm1_we_o			(wbm_d_dbg_we_o),
      .wbm1_cyc_o			(wbm_d_dbg_cyc_o),
      .wbm1_sel_o			(wbm_d_dbg_sel_o),
      .wbm1_stb_o			(wbm_d_dbg_stb_o),
      .wbm1_cti_o			(wbm_d_dbg_cti_o),
      .wbm1_bte_o			(wbm_d_dbg_bte_o),
      // Outputs to master from arbiter      
      .wbm1_dat_i			(wbm_d_dbg_dat_i),
      .wbm1_ack_i			(wbm_d_dbg_ack_i),
      .wbm1_err_i			(wbm_d_dbg_err_i),
      .wbm1_rty_i			(wbm_d_dbg_rty_i),

      // Slaves
      
      .wbs0_adr_i			(wbs_d_mc0_adr_i),
      .wbs0_dat_i			(wbs_d_mc0_dat_i),
      .wbs0_sel_i			(wbs_d_mc0_sel_i),
      .wbs0_we_i			(wbs_d_mc0_we_i),
      .wbs0_cyc_i			(wbs_d_mc0_cyc_i),
      .wbs0_stb_i			(wbs_d_mc0_stb_i),
      .wbs0_cti_i			(wbs_d_mc0_cti_i),
      .wbs0_bte_i			(wbs_d_mc0_bte_i),
      .wbs0_dat_o			(wbs_d_mc0_dat_o),
      .wbs0_ack_o			(wbs_d_mc0_ack_o),
      .wbs0_err_o			(wbs_d_mc0_err_o),
      .wbs0_rty_o			(wbs_d_mc0_rty_o),

      .wbs1_adr_i			(wbs_d_cellram_adr_i),
      .wbs1_dat_i			(wbs_d_cellram_dat_i),
      .wbs1_sel_i			(wbs_d_cellram_sel_i),
      .wbs1_we_i			(wbs_d_cellram_we_i),
      .wbs1_cyc_i			(wbs_d_cellram_cyc_i),
      .wbs1_stb_i			(wbs_d_cellram_stb_i),
      .wbs1_cti_i			(wbs_d_cellram_cti_i),
      .wbs1_bte_i			(wbs_d_cellram_bte_i),
      .wbs1_dat_o			(wbs_d_cellram_dat_o),
      .wbs1_ack_o			(wbs_d_cellram_ack_o),
      .wbs1_err_o			(wbs_d_cellram_err_o),
      .wbs1_rty_o			(wbs_d_cellram_rty_o),

      .wbs2_adr_i			(wbs_d_eth0_adr_i),
      .wbs2_dat_i			(wbs_d_eth0_dat_i),
      .wbs2_sel_i			(wbs_d_eth0_sel_i),
      .wbs2_we_i			(wbs_d_eth0_we_i),
      .wbs2_cyc_i			(wbs_d_eth0_cyc_i),
      .wbs2_stb_i			(wbs_d_eth0_stb_i),
      .wbs2_cti_i			(wbs_d_eth0_cti_i),
      .wbs2_bte_i			(wbs_d_eth0_bte_i),
      .wbs2_dat_o			(wbs_d_eth0_dat_o),
      .wbs2_ack_o			(wbs_d_eth0_ack_o),
      .wbs2_err_o			(wbs_d_eth0_err_o),
      .wbs2_rty_o			(wbs_d_eth0_rty_o),
      
      .wbs3_adr_i			(wbm_b_d_adr_o),
      .wbs3_dat_i			(wbm_b_d_dat_o),
      .wbs3_sel_i			(wbm_b_d_sel_o),
      .wbs3_we_i			(wbm_b_d_we_o),
      .wbs3_cyc_i			(wbm_b_d_cyc_o),
      .wbs3_stb_i			(wbm_b_d_stb_o),
      .wbs3_cti_i			(wbm_b_d_cti_o),
      .wbs3_bte_i			(wbm_b_d_bte_o),
      .wbs3_dat_o			(wbm_b_d_dat_i),
      .wbs3_ack_o			(wbm_b_d_ack_i),
      .wbs3_err_o			(wbm_b_d_err_i),
      .wbs3_rty_o			(wbm_b_d_rty_i),

      // Clock, reset inputs
      .wb_clk			(wb_clk),
      .wb_rst			(wb_rst));


   //
   // Wishbone byte-wide bus arbiter
   //   
   
   arbiter_bytebus 
     #(   
	  .wb_addr_match_width(bbus_arb_wb_addr_match_width),
	  .wb_num_slaves(bbus_arb_wb_num_slaves),

	  .slave0_adr(bbus_arb_slave0_adr),
	  .slave1_adr(bbus_arb_slave1_adr),
	  .slave2_adr(bbus_arb_slave2_adr),
	  .slave3_adr(bbus_arb_slave3_adr),
	  .slave4_adr(bbus_arb_slave4_adr)
	  )
   arbiter_bytebus0
     (

      // Master 0
      // Inputs to arbiter from master
      .wbm0_adr_o			(wbm_b_d_adr_o),
      .wbm0_dat_o			(wbm_b_d_dat_o),
      .wbm0_sel_o			(wbm_b_d_sel_o),
      .wbm0_we_o			(wbm_b_d_we_o),
      .wbm0_cyc_o			(wbm_b_d_cyc_o),
      .wbm0_stb_o			(wbm_b_d_stb_o),
      .wbm0_cti_o			(wbm_b_d_cti_o),
      .wbm0_bte_o			(wbm_b_d_bte_o),
      // Outputs to master from arbiter
      .wbm0_dat_i			(wbm_b_d_dat_i),
      .wbm0_ack_i			(wbm_b_d_ack_i),
      .wbm0_err_i			(wbm_b_d_err_i),
      .wbm0_rty_i			(wbm_b_d_rty_i),

      // Byte bus slaves
      
      .wbs0_adr_i			(wbs_d_uart0_adr_i),
      .wbs0_dat_i			(wbs_d_uart0_dat_i),
      .wbs0_we_i			(wbs_d_uart0_we_i),
      .wbs0_cyc_i			(wbs_d_uart0_cyc_i),
      .wbs0_stb_i			(wbs_d_uart0_stb_i),
      .wbs0_cti_i			(wbs_d_uart0_cti_i),
      .wbs0_bte_i			(wbs_d_uart0_bte_i),
      .wbs0_dat_o			(wbs_d_uart0_dat_o),
      .wbs0_ack_o			(wbs_d_uart0_ack_o),
      .wbs0_err_o			(wbs_d_uart0_err_o),
      .wbs0_rty_o			(wbs_d_uart0_rty_o),

      .wbs1_adr_i			(wbs_d_gpio0_adr_i),
      .wbs1_dat_i			(wbs_d_gpio0_dat_i),
      .wbs1_we_i			(wbs_d_gpio0_we_i),
      .wbs1_cyc_i			(wbs_d_gpio0_cyc_i),
      .wbs1_stb_i			(wbs_d_gpio0_stb_i),
      .wbs1_cti_i			(wbs_d_gpio0_cti_i),
      .wbs1_bte_i			(wbs_d_gpio0_bte_i),
      .wbs1_dat_o			(wbs_d_gpio0_dat_o),
      .wbs1_ack_o			(wbs_d_gpio0_ack_o),
      .wbs1_err_o			(wbs_d_gpio0_err_o),
      .wbs1_rty_o			(wbs_d_gpio0_rty_o),

      .wbs2_adr_i			(wbs_d_i2c0_adr_i),
      .wbs2_dat_i			(wbs_d_i2c0_dat_i),
      .wbs2_we_i			(wbs_d_i2c0_we_i), 
      .wbs2_cyc_i			(wbs_d_i2c0_cyc_i),
      .wbs2_stb_i			(wbs_d_i2c0_stb_i),
      .wbs2_cti_i			(wbs_d_i2c0_cti_i),
      .wbs2_bte_i			(wbs_d_i2c0_bte_i),
      .wbs2_dat_o			(wbs_d_i2c0_dat_o),
      .wbs2_ack_o			(wbs_d_i2c0_ack_o),
      .wbs2_err_o			(wbs_d_i2c0_err_o),
      .wbs2_rty_o			(wbs_d_i2c0_rty_o),

      .wbs3_adr_i			(wbs_d_i2c1_adr_i),
      .wbs3_dat_i			(wbs_d_i2c1_dat_i),
      .wbs3_we_i			(wbs_d_i2c1_we_i), 
      .wbs3_cyc_i			(wbs_d_i2c1_cyc_i),
      .wbs3_stb_i			(wbs_d_i2c1_stb_i),
      .wbs3_cti_i			(wbs_d_i2c1_cti_i),
      .wbs3_bte_i			(wbs_d_i2c1_bte_i),
      .wbs3_dat_o			(wbs_d_i2c1_dat_o),
      .wbs3_ack_o			(wbs_d_i2c1_ack_o),
      .wbs3_err_o			(wbs_d_i2c1_err_o),
      .wbs3_rty_o			(wbs_d_i2c1_rty_o),

      .wbs4_adr_i			(wbs_d_spi0_adr_i),
      .wbs4_dat_i			(wbs_d_spi0_dat_i),
      .wbs4_we_i			(wbs_d_spi0_we_i), 
      .wbs4_cyc_i			(wbs_d_spi0_cyc_i),
      .wbs4_stb_i			(wbs_d_spi0_stb_i),
      .wbs4_cti_i			(wbs_d_spi0_cti_i),
      .wbs4_bte_i			(wbs_d_spi0_bte_i),
      .wbs4_dat_o			(wbs_d_spi0_dat_o),
      .wbs4_ack_o			(wbs_d_spi0_ack_o),
      .wbs4_err_o			(wbs_d_spi0_err_o),
      .wbs4_rty_o			(wbs_d_spi0_rty_o),

      // Clock, reset inputs
      .wb_clk			(wb_clk),
      .wb_rst			(wb_rst));


`ifdef JTAG_DEBUG   
   ////////////////////////////////////////////////////////////////////////
   //
   // JTAG TAP
   // 
   ////////////////////////////////////////////////////////////////////////

   //
   // Wires
   //
   wire 				  dbg_if_select;   
   wire 				  dbg_if_tdo;
   wire 				  jtag_tap_tdo;   
   wire 				  jtag_tap_shift_dr, jtag_tap_pause_dr, 
					  jtag_tap_upate_dr, jtag_tap_capture_dr;
   //
   // Instantiation
   //

   jtag_tap jtag_tap0
     (
      // Ports to pads
      .tdo_pad_o			(tdo_pad_o),
      .tms_pad_i			(tms_pad_i),
      .tck_pad_i			(dbg_tck),
      .trst_pad_i			(rst_i),
      .tdi_pad_i			(tdi_pad_i),
      
      .tdo_padoe_o			(tdo_padoe_o),
      
      .tdo_o				(jtag_tap_tdo),

      .shift_dr_o			(jtag_tap_shift_dr),
      .pause_dr_o			(jtag_tap_pause_dr),
      .update_dr_o			(jtag_tap_update_dr),
      .capture_dr_o			(jtag_tap_capture_dr),
      
      .extest_select_o			(),
      .sample_preload_select_o		(),
      .mbist_select_o			(),
      .debug_select_o			(dbg_if_select),

      
      .bs_chain_tdi_i			(1'b0),
      .mbist_tdi_i			(1'b0),
      .debug_tdi_i			(dbg_if_tdo)
      
      );
   
   ////////////////////////////////////////////////////////////////////////
`endif //  `ifdef JTAG_DEBUG

   ////////////////////////////////////////////////////////////////////////
   //
   // OpenRISC processor
   // 
   ////////////////////////////////////////////////////////////////////////

   // 
   // Wires
   // 
   
   wire [30:0] 				  cpu_irq;

   wire [31:0] 				  or1k_dbg_dat_i;
   wire [31:0] 				  or1k_dbg_adr_i;
   wire 				  or1k_dbg_we_i;
   wire 				  or1k_dbg_stb_i;
   wire 				  or1k_dbg_ack_o;
   wire [31:0] 				  or1k_dbg_dat_o;
   
   wire 				  or1k_dbg_stall_i;
   wire 				  or1k_dbg_ewt_i;
   wire [3:0] 				  or1k_dbg_lss_o;
   wire [1:0] 				  or1k_dbg_is_o;
   wire [10:0] 				  or1k_dbg_wp_o;
   wire 				  or1k_dbg_bp_o;
   wire 				  or1k_dbg_rst;   
   
   wire 				  or1200_clk, or1200_rst;
   wire 				  sig_tick;
   
   //
   // Assigns
   //
   assign or1200_clk = wb_clk;
   assign or1200_rst = wb_rst | or1k_dbg_rst;
`ifdef OR1200
   // 
   // Instantiation
   //    
   or1200_top or1200_top0
       (
	// Instruction bus, clocks, reset
	.iwb_clk_i			(wb_clk),
	.iwb_rst_i			(wb_rst),
	.iwb_ack_i			(wbm_i_or12_ack_i),
	.iwb_err_i			(wbm_i_or12_err_i),
	.iwb_rty_i			(wbm_i_or12_rty_i),
	.iwb_dat_i			(wbm_i_or12_dat_i),
	
	.iwb_cyc_o			(wbm_i_or12_cyc_o),
	.iwb_adr_o			(wbm_i_or12_adr_o),
	.iwb_stb_o			(wbm_i_or12_stb_o),
	.iwb_we_o				(wbm_i_or12_we_o),
	.iwb_sel_o			(wbm_i_or12_sel_o),
	.iwb_dat_o			(wbm_i_or12_dat_o),
	.iwb_cti_o			(wbm_i_or12_cti_o),
	.iwb_bte_o			(wbm_i_or12_bte_o),
	
	// Data bus, clocks, reset            
	.dwb_clk_i			(wb_clk),
	.dwb_rst_i			(wb_rst),
	.dwb_ack_i			(wbm_d_or12_ack_i),
	.dwb_err_i			(wbm_d_or12_err_i),
	.dwb_rty_i			(wbm_d_or12_rty_i),
	.dwb_dat_i			(wbm_d_or12_dat_i),

	.dwb_cyc_o			(wbm_d_or12_cyc_o),
	.dwb_adr_o			(wbm_d_or12_adr_o),
	.dwb_stb_o			(wbm_d_or12_stb_o),
	.dwb_we_o				(wbm_d_or12_we_o),
	.dwb_sel_o			(wbm_d_or12_sel_o),
	.dwb_dat_o			(wbm_d_or12_dat_o),
	.dwb_cti_o			(wbm_d_or12_cti_o),
	.dwb_bte_o			(wbm_d_or12_bte_o),
	
	// Debug interface ports
	.dbg_stall_i			(or1k_dbg_stall_i),
	//.dbg_ewt_i			(or1k_dbg_ewt_i),
	.dbg_ewt_i			(1'b0),
	.dbg_lss_o			(or1k_dbg_lss_o),
	.dbg_is_o				(or1k_dbg_is_o),
	.dbg_wp_o				(or1k_dbg_wp_o),
	.dbg_bp_o				(or1k_dbg_bp_o),

	.dbg_adr_i			(or1k_dbg_adr_i),      
	.dbg_we_i				(or1k_dbg_we_i ), 
	.dbg_stb_i			(or1k_dbg_stb_i),          
	.dbg_dat_i			(or1k_dbg_dat_i),
	.dbg_dat_o			(or1k_dbg_dat_o),
	.dbg_ack_o			(or1k_dbg_ack_o),
	
	.pm_clksd_o			(),
	.pm_dc_gate_o			(),
	.pm_ic_gate_o			(),
	.pm_dmmu_gate_o			(),
	.pm_immu_gate_o			(),
	.pm_tt_gate_o			(),
	.pm_cpu_gate_o			(),
	.pm_wakeup_o			(),
	.pm_lvolt_o			(),

	// Core clocks, resets
	.clk_i				(or1200_clk),
	.rst_i				(or1200_rst),
	
	.clmode_i				(2'b00),
	// Interrupts      
	.pic_ints_i			(cpu_irq),
	.sig_tick(sig_tick),
	/*
	 .mbist_so_o			(),
	 .mbist_si_i			(0),
	 .mbist_ctrl_i			(0),
	 */

	.pm_cpustall_i			(1'b0)

	);
`endif   
   ////////////////////////////////////////////////////////////////////////

   
`ifdef MOR1KX

   mor1kx
     #(
 `ifdef JTAG_DEBUG
       .FEATURE_DEBUGUNIT("ENABLED"),
 `endif
       .OPTION_SHIFTER("SERIAL"),
       .FEATURE_SYSCALL("ENABLED"),
       .FEATURE_DIVIDER("SERIAL"),
       .FEATURE_MULTIPLIER("THREESTAGE"),
       .OPTION_CPU0("PRONTO_ESPRESSO"),
       .OPTION_PIC_TRIGGER("LATCHED_LEVEL"),
       // Boot out of bootrom
       .OPTION_RESET_PC({rom0_wb_adr,28'd0})
       )
     mor1kx0
     (
      .iwbm_adr_o(wbm_i_or12_adr_o),
      .iwbm_stb_o(wbm_i_or12_stb_o),
      .iwbm_cyc_o(wbm_i_or12_cyc_o),
      .iwbm_sel_o(wbm_i_or12_sel_o),
      .iwbm_we_o (wbm_i_or12_we_o ),
      .iwbm_cti_o(wbm_i_or12_cti_o),
      .iwbm_bte_o(wbm_i_or12_bte_o),
      .iwbm_dat_o(wbm_i_or12_dat_o),
      
      .dwbm_adr_o(wbm_d_or12_adr_o),
      .dwbm_stb_o(wbm_d_or12_stb_o),
      .dwbm_cyc_o(wbm_d_or12_cyc_o),
      .dwbm_sel_o(wbm_d_or12_sel_o),
      .dwbm_we_o (wbm_d_or12_we_o ),
      .dwbm_cti_o(wbm_d_or12_cti_o),
      .dwbm_bte_o(wbm_d_or12_bte_o),
      .dwbm_dat_o(wbm_d_or12_dat_o),
      
      .clk(wb_clk),
      .rst(wb_rst),
      
      .iwbm_err_i(wbm_i_or12_err_i),
      .iwbm_ack_i(wbm_i_or12_ack_i),
      .iwbm_dat_i(wbm_i_or12_dat_i),
      .iwbm_rty_i(wbm_i_or12_rty_i),
      
      .dwbm_err_i(wbm_d_or12_err_i),
      .dwbm_ack_i(wbm_d_or12_ack_i),
      .dwbm_dat_i(wbm_d_or12_dat_i),
      .dwbm_rty_i(wbm_d_or12_rty_i),

      .irq_i({12'd0,cpu_irq[19:0]}),

      .du_addr_i(or1k_dbg_adr_i[15:0]),
      .du_stb_i(or1k_dbg_stb_i),
      .du_dat_i(or1k_dbg_dat_i),
      .du_we_i(or1k_dbg_we_i),
      .du_dat_o(or1k_dbg_dat_o),
      .du_ack_o(or1k_dbg_ack_o),
      .du_stall_i(or1k_dbg_stall_i),
      .du_stall_o(or1k_dbg_bp_o)

      );

`endif   


`ifdef JTAG_DEBUG
   ////////////////////////////////////////////////////////////////////////
	 //
   // OR1200 Debug Interface
   // 
   ////////////////////////////////////////////////////////////////////////
   
   dbg_if dbg_if0
     (
      // OR1200 interface
      .cpu0_clk_i			(or1200_clk),
      .cpu0_rst_o			(or1k_dbg_rst),      
      .cpu0_addr_o			(or1k_dbg_adr_i),
      .cpu0_data_o			(or1k_dbg_dat_i),
      .cpu0_stb_o			(or1k_dbg_stb_i),
      .cpu0_we_o			(or1k_dbg_we_i),
      .cpu0_data_i			(or1k_dbg_dat_o),
      .cpu0_ack_i			(or1k_dbg_ack_o),      


      .cpu0_stall_o			(or1k_dbg_stall_i),
      .cpu0_bp_i			(or1k_dbg_bp_o),      
      
      // TAP interface
      .tck_i				(dbg_tck),
      .tdi_i				(jtag_tap_tdo),
      .tdo_o				(dbg_if_tdo),      
      .rst_i				(rst_i),
      .shift_dr_i			(jtag_tap_shift_dr),
      .pause_dr_i			(jtag_tap_pause_dr),
      .update_dr_i			(jtag_tap_update_dr),
      .debug_select_i			(dbg_if_select),

      // Wishbone debug master
      .wb_clk_i				(wb_clk),
      .wb_dat_i				(wbm_d_dbg_dat_i),
      .wb_ack_i				(wbm_d_dbg_ack_i),
      .wb_err_i				(wbm_d_dbg_err_i),
      .wb_adr_o				(wbm_d_dbg_adr_o),
      .wb_dat_o				(wbm_d_dbg_dat_o),
      .wb_cyc_o				(wbm_d_dbg_cyc_o),
      .wb_stb_o				(wbm_d_dbg_stb_o),
      .wb_sel_o				(wbm_d_dbg_sel_o),
      .wb_we_o				(wbm_d_dbg_we_o ),
      .wb_cti_o				(wbm_d_dbg_cti_o),
      .wb_cab_o                         (/*   UNUSED  */),
      .wb_bte_o				(wbm_d_dbg_bte_o)
      );
   
   ////////////////////////////////////////////////////////////////////////   
`else // !`ifdef JTAG_DEBUG

   assign wbm_d_dbg_adr_o = 0;   
   assign wbm_d_dbg_dat_o = 0;   
   assign wbm_d_dbg_cyc_o = 0;   
   assign wbm_d_dbg_stb_o = 0;   
   assign wbm_d_dbg_sel_o = 0;   
   assign wbm_d_dbg_we_o  = 0;   
   assign wbm_d_dbg_cti_o = 0;   
   assign wbm_d_dbg_bte_o = 0;  

   assign or1k_dbg_adr_i = 0;   
   assign or1k_dbg_dat_i = 0;   
   assign or1k_dbg_stb_i = 0;   
   assign or1k_dbg_we_i = 0;
   assign or1k_dbg_stall_i = 0;
   
   ////////////////////////////////////////////////////////////////////////   
`endif // !`ifdef JTAG_DEBUG
   

   ////////////////////////////////////////////////////////////////////////
   //
   // ROM
   // 
   ////////////////////////////////////////////////////////////////////////
   
   rom rom0
     (
      .wb_dat_o				(wbs_i_rom0_dat_o),
      .wb_ack_o				(wbs_i_rom0_ack_o),
      .wb_adr_i				(wbs_i_rom0_adr_i[(wbs_i_rom0_addr_width+2)-1:2]),
      .wb_stb_i				(wbs_i_rom0_stb_i),
      .wb_cyc_i				(wbs_i_rom0_cyc_i),
      .wb_cti_i				(wbs_i_rom0_cti_i),
      .wb_bte_i				(wbs_i_rom0_bte_i),
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst));

   defparam rom0.addr_width = wbs_i_rom0_addr_width;

   assign wbs_i_rom0_err_o = 0;
   assign wbs_i_rom0_rty_o = 0;
   
   ////////////////////////////////////////////////////////////////////////

`ifdef RAM_WB
   ////////////////////////////////////////////////////////////////////////
   //
   // Generic RAM
   // 
   ////////////////////////////////////////////////////////////////////////

   ram_wb 
   #(.aw(wb_aw),
     .dw(wb_dw),
     .mem_size_bytes(internal_sram_mem_span),
     .mem_adr_width(internal_sram_adr_width_for_span)
     )
   ram_wb0
     (
      // Wishbone slave interface 0
      .wbm0_dat_i			(wbs_i_mc0_dat_i),
      .wbm0_adr_i			(wbs_i_mc0_adr_i),
      .wbm0_sel_i			(wbs_i_mc0_sel_i),
      .wbm0_cti_i			(wbs_i_mc0_cti_i),
      .wbm0_bte_i			(wbs_i_mc0_bte_i),
      .wbm0_we_i			(wbs_i_mc0_we_i ),
      .wbm0_cyc_i			(wbs_i_mc0_cyc_i),
      .wbm0_stb_i			(wbs_i_mc0_stb_i),
      .wbm0_dat_o			(wbs_i_mc0_dat_o),
      .wbm0_ack_o			(wbs_i_mc0_ack_o),
      .wbm0_err_o                       (wbs_i_mc0_err_o),
      .wbm0_rty_o                       (wbs_i_mc0_rty_o),
      // Wishbone slave interface 1
      .wbm1_dat_i			(wbs_d_mc0_dat_i),
      .wbm1_adr_i			(wbs_d_mc0_adr_i),
      .wbm1_sel_i			(wbs_d_mc0_sel_i),
      .wbm1_cti_i			(wbs_d_mc0_cti_i),
      .wbm1_bte_i			(wbs_d_mc0_bte_i),
      .wbm1_we_i			(wbs_d_mc0_we_i ),
      .wbm1_cyc_i			(wbs_d_mc0_cyc_i),
      .wbm1_stb_i			(wbs_d_mc0_stb_i),
      .wbm1_dat_o			(wbs_d_mc0_dat_o),
      .wbm1_ack_o			(wbs_d_mc0_ack_o),
      .wbm1_err_o                       (wbs_d_mc0_err_o),
      .wbm1_rty_o                       (wbs_d_mc0_rty_o),     
      // Wishbone slave interface 2
      .wbm2_dat_i			(wbm_eth0_dat_o),
      .wbm2_adr_i			(wbm_eth0_adr_o),
      .wbm2_sel_i			(wbm_eth0_sel_o),
      .wbm2_cti_i			(wbm_eth0_cti_o),
      .wbm2_bte_i			(wbm_eth0_bte_o),
      .wbm2_we_i			(wbm_eth0_we_o ),
      .wbm2_cyc_i			(wbm_eth0_cyc_o),
      .wbm2_stb_i			(wbm_eth0_stb_o),
      .wbm2_dat_o			(wbm_eth0_dat_i),
      .wbm2_ack_o			(wbm_eth0_ack_i),
      .wbm2_err_o                       (wbm_eth0_err_i),
      .wbm2_rty_o                       (wbm_eth0_rty_i),       
      // Clock, reset
      .wb_clk_i				(wb_clk),
      .wb_rst_i				(wb_rst));
   ////////////////////////////////////////////////////////////////////////
`endif //  `ifdef RAM_WB

`ifdef CELLRAM

   /* Lighweight arbiter between instruction and data busses going
    into the cellram controller */

   wire [31:0] 				  cellram_wb_adr_i;
   wire [31:0] 				  cellram_wb_dat_i;
   wire [31:0] 				  cellram_wb_dat_o;
   wire [3:0] 				  cellram_wb_sel_i;
   wire 				  cellram_wb_cyc_i;
   wire 				  cellram_wb_stb_i;
   wire 				  cellram_wb_we_i;
   wire 				  cellram_wb_ack_o;

   reg [1:0] 				  cellram_mst_sel;
   
   reg [9:0] 				  cellram_arb_timeout;
   wire 				  cellram_arb_reset;
   
   always @(posedge wb_clk)
     if (wb_rst)
       cellram_mst_sel <= 0;
     else begin
	if (cellram_mst_sel==2'b00) begin
	   /* wait for new access from masters. data takes priority */
	   if (wbs_d_cellram_cyc_i & wbs_d_cellram_stb_i)
	     cellram_mst_sel[1] <= 1;
	   else if (wbs_i_cellram_cyc_i & wbs_i_cellram_stb_i)
	     cellram_mst_sel[0] <= 1;
	end
	else begin
	   if (cellram_wb_ack_o | cellram_arb_reset)
	     cellram_mst_sel <= 0;
	end // else: !if(cellram_mst_sel==2'b00)
     end // else: !if(wb_rst)

   reg [3:0] cellram_rst_counter;
   always @(posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       cellram_rst_counter <= 4'hf;
     else if (|cellram_rst_counter)
       cellram_rst_counter <= cellram_rst_counter - 1;
   
   assign cellram_wb_adr_i = cellram_mst_sel[0] ? wbs_i_cellram_adr_i :
			   wbs_d_cellram_adr_i;
   assign cellram_wb_dat_i = cellram_mst_sel[0] ? wbs_i_cellram_dat_i :
			   wbs_d_cellram_dat_i;
   assign cellram_wb_stb_i = (cellram_mst_sel[0] ?  wbs_i_cellram_stb_i :
			   cellram_mst_sel[1]  ? wbs_d_cellram_stb_i : 0) &
			   !(|cellram_rst_counter);
   assign cellram_wb_cyc_i = cellram_mst_sel[0] ?  wbs_i_cellram_cyc_i :
			   cellram_mst_sel[1] ?  wbs_d_cellram_cyc_i : 0;
   assign cellram_wb_we_i = cellram_mst_sel[0] ? wbs_i_cellram_we_i :
			  wbs_d_cellram_we_i;
   assign cellram_wb_sel_i = cellram_mst_sel[0] ? wbs_i_cellram_sel_i :
			  wbs_d_cellram_sel_i;

   assign wbs_i_cellram_dat_o = cellram_wb_dat_o;
   assign wbs_d_cellram_dat_o = cellram_wb_dat_o;
   assign wbs_i_cellram_ack_o = cellram_wb_ack_o & cellram_mst_sel[0];
   assign wbs_d_cellram_ack_o = cellram_wb_ack_o & cellram_mst_sel[1];
   assign wbs_i_cellram_err_o = cellram_arb_reset & cellram_mst_sel[0];
   assign wbs_i_cellram_rty_o = 0;
   assign wbs_d_cellram_err_o = cellram_arb_reset & cellram_mst_sel[1];
   assign wbs_d_cellram_rty_o = 0;

   
   always @(posedge wb_clk)
     if (wb_rst)
       cellram_arb_timeout <= 0;
     else if (cellram_wb_ack_o)
       cellram_arb_timeout <= 0;
     else if (cellram_wb_stb_i & cellram_wb_cyc_i)
       cellram_arb_timeout <= cellram_arb_timeout + 1;

   assign cellram_arb_reset = (&cellram_arb_timeout);
   
   cellram_ctrl
     /* Use the simple flash interface */
     #(
       .cellram_read_cycles(4), // 70ns in cycles, at 50MHz 4=80ns
       .cellram_write_cycles(4)) // 70ns in cycles, at 50Mhz 4=80ns
     cellram_ctrl0
     (
      .wb_clk_i(wb_clk), 
      .wb_rst_i(wb_rst | cellram_arb_reset),

      .wb_adr_i(cellram_wb_adr_i),
      .wb_dat_i(cellram_wb_dat_i),
      .wb_stb_i(cellram_wb_stb_i),
      .wb_cyc_i(cellram_wb_cyc_i),
      .wb_we_i (cellram_wb_we_i ),
      .wb_sel_i(cellram_wb_sel_i),
      .wb_dat_o(cellram_wb_dat_o),
      .wb_ack_o(cellram_wb_ack_o), 
      .wb_err_o(),
      .wb_rty_o(),
      
      .cellram_dq_io(cellram_dq_io),
      .cellram_adr_o(cellram_adr_o),
      .cellram_adv_n_o(cellram_adv_n_o),
      .cellram_ce_n_o(cellram_ce_n_o),
      .cellram_clk_o(cellram_clk_o),
      .cellram_oe_n_o(cellram_oe_n_o),
      .cellram_rst_n_o(),
      .cellram_wait_i(cellram_wait_i),
      .cellram_we_n_o(cellram_we_n_o),
      .cellram_wp_n_o(),
      .cellram_lb_n_o(cellram_lb_n_o),
      .cellram_ub_n_o(cellram_ub_n_o),
      .cellram_cre_o(cellram_cre_o)
      );


`else

   assign wbs_i_cellram_dat_o = 0;
   assign wbs_i_cellram_ack_o = 0;
   assign wbs_i_cellram_err_o = 0;
   assign wbs_i_cellram_rty_o = 0;

   assign wbs_d_cellram_dat_o = 0;
   assign wbs_d_cellram_ack_o = 0;
   assign wbs_d_cellram_err_o = 0;
   assign wbs_d_cellram_rty_o = 0;
   
`endif //  `ifdef CELLRAM
   
`ifdef ETH0

   //
   // Wires
   //
   wire        eth0_irq;
   wire [3:0]  eth0_mtxd;
   wire        eth0_mtxen;
   wire        eth0_mtxerr;
   wire        eth0_mtx_clk;
   wire        eth0_mrx_clk;
   wire [3:0]  eth0_mrxd;
   wire        eth0_mrxdv;
   wire        eth0_mrxerr;
   wire        eth0_mcoll;
   wire        eth0_mcrs;
   wire        eth0_speed;
   wire        eth0_duplex;
   wire        eth0_link;
   // Management interface wires
   wire        eth0_md_i;
   wire        eth0_md_o;
   wire        eth0_md_oe;


   //
   // assigns

   // Hook up MII wires
   assign eth0_mtx_clk   = eth0_tx_clk;
   assign eth0_tx_data   = eth0_mtxd[3:0];
   assign eth0_tx_en     = eth0_mtxen;
   assign eth0_tx_er     = eth0_mtxerr;
   assign eth0_mrxd[3:0] = eth0_rx_data;
   assign eth0_mrxdv     = eth0_dv;
   assign eth0_mrxerr    = eth0_rx_er;
   assign eth0_mrx_clk   = eth0_rx_clk;
   assign eth0_mcoll     = eth0_col;
   assign eth0_mcrs      = eth0_crs;

`ifdef XILINX
   // Xilinx primitive for MDIO tristate
   IOBUF iobuf_phy_smi_data
     (
      // Outputs
      .O                                 (eth0_md_i),
      // Inouts
      .IO                                (eth0_md_pad_io),
      // Inputs
      .I                                 (eth0_md_o),
      .T                                 (!eth0_md_oe));   
`else // !`ifdef XILINX
   
   // Generic technology tristate control for management interface
   assign eth0_md_pad_io = eth0_md_oe ? eth0_md_o : 1'bz;
   assign eth0_md_i = eth0_md_pad_io;
   
`endif // !`ifdef XILINX

`ifdef ETH0_PHY_RST
   assign eth0_rst_n_o = !wb_rst;
`endif
   
   ethmac ethmac0
     (
      // Wishbone Slave interface
      .wb_clk_i		(wb_clk),
      .wb_rst_i		(wb_rst),
      .wb_dat_i		(wbs_d_eth0_dat_i[31:0]),
      .wb_adr_i		(wbs_d_eth0_adr_i[wbs_d_eth0_addr_width-1:2]),
      .wb_sel_i		(wbs_d_eth0_sel_i[3:0]),
      .wb_we_i 		(wbs_d_eth0_we_i),
      .wb_cyc_i		(wbs_d_eth0_cyc_i),
      .wb_stb_i		(wbs_d_eth0_stb_i),
      .wb_dat_o		(wbs_d_eth0_dat_o[31:0]),
      .wb_err_o		(wbs_d_eth0_err_o),
      .wb_ack_o		(wbs_d_eth0_ack_o),
      // Wishbone Master Interface
      .m_wb_adr_o	(wbm_eth0_adr_o[31:0]),
      .m_wb_sel_o	(wbm_eth0_sel_o[3:0]),
      .m_wb_we_o 	(wbm_eth0_we_o),
      .m_wb_dat_o	(wbm_eth0_dat_o[31:0]),
      .m_wb_cyc_o	(wbm_eth0_cyc_o),
      .m_wb_stb_o	(wbm_eth0_stb_o),
      .m_wb_cti_o	(wbm_eth0_cti_o[2:0]),
      .m_wb_bte_o	(wbm_eth0_bte_o[1:0]),
      .m_wb_dat_i	(wbm_eth0_dat_i[31:0]),
      .m_wb_ack_i	(wbm_eth0_ack_i),
      .m_wb_err_i	(wbm_eth0_err_i),

      // Ethernet MII interface
      // Transmit
      .mtxd_pad_o	(eth0_mtxd[3:0]),
      .mtxen_pad_o	(eth0_mtxen),
      .mtxerr_pad_o	(eth0_mtxerr),
      .mtx_clk_pad_i	(eth0_mtx_clk),
      // Receive
      .mrx_clk_pad_i	(eth0_mrx_clk),
      .mrxd_pad_i	(eth0_mrxd[3:0]),
      .mrxdv_pad_i	(eth0_mrxdv),
      .mrxerr_pad_i	(eth0_mrxerr),
      .mcoll_pad_i	(eth0_mcoll),
      .mcrs_pad_i	(eth0_mcrs),
      // Management interface
      .md_pad_i		(eth0_md_i),
      .mdc_pad_o	(eth0_mdc_pad_o),
      .md_pad_o		(eth0_md_o),
      .md_padoe_o	(eth0_md_oe),

      // Processor interrupt
      .int_o		(eth0_irq)
      
      /*
       .mbist_so_o			(),
       .mbist_si_i			(),
       .mbist_ctrl_i			()
       */
      
      );

   assign wbs_d_eth0_rty_o = 0;

`else
   assign wbs_d_eth0_dat_o = 0;
   assign wbs_d_eth0_err_o = 0;
   assign wbs_d_eth0_ack_o = 0;
   assign wbs_d_eth0_rty_o = 0;
   assign wbm_eth0_adr_o = 0;
   assign wbm_eth0_sel_o = 0;
   assign wbm_eth0_we_o = 0;
   assign wbm_eth0_dat_o = 0;
   assign wbm_eth0_cyc_o = 0;
   assign wbm_eth0_stb_o = 0;
   assign wbm_eth0_cti_o = 0;
   assign wbm_eth0_bte_o = 0;
`endif
   
`ifdef UART0
   ////////////////////////////////////////////////////////////////////////
   //
   // UART0
   // 
   ////////////////////////////////////////////////////////////////////////

   //
   // Wires
   //
   wire        uart0_srx;
   wire        uart0_stx;
   
   wire        uart0_irq;

   //
   // Assigns
   //
   assign wbs_d_uart0_err_o = 0;
   assign wbs_d_uart0_rty_o = 0;

   // Two UART lines coming to single one (ensure they go high when unconnected)
   assign uart0_srx = uart0_srx_pad_i; //& uart0_srx_expheader_pad_i;
   assign uart0_stx_pad_o = uart0_stx;
   //assign uart0_stx_expheader_pad_o = uart0_stx;
   
   
   uart16550 uart16550_0
     (
      // Wishbone slave interface
      .wb_clk_i				(wb_clk),
      .wb_rst_i				(wb_rst),
      .wb_adr_i				(wbs_d_uart0_adr_i[uart0_addr_width-1:0]),
      .wb_dat_i				(wbs_d_uart0_dat_i),
      .wb_we_i				(wbs_d_uart0_we_i),
      .wb_stb_i				(wbs_d_uart0_stb_i),
      .wb_cyc_i				(wbs_d_uart0_cyc_i),
      //.wb_sel_i				(),
      .wb_dat_o				(wbs_d_uart0_dat_o),
      .wb_ack_o				(wbs_d_uart0_ack_o),

      .int_o				(uart0_irq),
      .stx_pad_o			(uart0_stx),
      .rts_pad_o			(),
      .dtr_pad_o			(),
      //      .baud_o				(),
      // Inputs
      .srx_pad_i			(uart0_srx),
      .cts_pad_i			(1'b0),
      .dsr_pad_i			(1'b0),
      .ri_pad_i				(1'b0),
      .dcd_pad_i			(1'b0));

   ////////////////////////////////////////////////////////////////////////          
`else // !`ifdef UART0
   
   //
   // Assigns
   //
   assign wbs_d_uart0_err_o = 0;   
   assign wbs_d_uart0_rty_o = 0;
   assign wbs_d_uart0_ack_o = 0;
   assign wbs_d_uart0_dat_o = 0;
   
   ////////////////////////////////////////////////////////////////////////       
`endif // !`ifdef UART0
   
`ifdef SPI0   
   ////////////////////////////////////////////////////////////////////////
   //
   // SPI0 controller
   // 
   ////////////////////////////////////////////////////////////////////////

   //
   // Wires
   //
   wire 			     spi0_irq;

   //
   // Assigns
   //
   assign wbs_d_spi0_err_o = 0;
   assign wbs_d_spi0_rty_o = 0;
   //assign spi0_hold_n_o = 1;
   //assign spi0_w_n_o = 1;
   
   
   simple_spi spi0
     (
      // Wishbone slave interface
      .clk_i				(wb_clk),
      .rst_i				(wb_rst),
      .cyc_i				(wbs_d_spi0_cyc_i),
      .stb_i				(wbs_d_spi0_stb_i),
      .adr_i				(wbs_d_spi0_adr_i[spi0_wb_adr_width-1:0]),
      .we_i				(wbs_d_spi0_we_i),
      .dat_i				(wbs_d_spi0_dat_i),
      .dat_o				(wbs_d_spi0_dat_o),
      .ack_o				(wbs_d_spi0_ack_o),
      // SPI IRQ
      .inta_o				(spi0_irq),
      // External SPI interface
      .sck_o				(spi0_sck_o),
      .ss_o                             (spi0_ss_o),
      .mosi_o				(spi0_mosi_o),      
      .miso_i				(spi0_miso_i)
      );

   defparam spi0.slave_select_width = spi0_ss_width;

   // SPI clock and MISO lines must go through STARTUP_VIRTEX5 block.
   STARTUP_VIRTEX5 startup_virtex5
     (
      .CFGCLK(),
      .CFGMCLK(),
      .DINSPI(spi0_miso_i),
      .EOS(),
      .TCKSPI(),
      .CLK(),
      .GSR(1'b0),
      .GTS(1'b0),
      .USRCCLKO(spi0_sck_o),
      .USRCCLKTS(1'b0),
      .USRDONEO(),
      .USRDONETS()
      );
   
   ////////////////////////////////////////////////////////////////////////   
`else // !`ifdef SPI0

   //
   // Assigns
   //
   assign wbs_d_spi0_dat_o = 0;
   assign wbs_d_spi0_ack_o = 0;   
   assign wbs_d_spi0_err_o = 0;
   assign wbs_d_spi0_rty_o = 0;
   
   ////////////////////////////////////////////////////////////////////////
`endif // !`ifdef SPI0   


`ifdef I2C0
   ////////////////////////////////////////////////////////////////////////
   //
   // i2c controller 0
   // 
   ////////////////////////////////////////////////////////////////////////

   //
   // Wires
   //
   wire 			     i2c0_irq;
   wire 			     scl0_pad_o;
   wire 			     scl0_padoen_o;
   wire 			     sda0_pad_o;
   wire 			     sda0_padoen_o;
   
  i2c_master_slave
    #
    (
     .DEFAULT_SLAVE_ADDR(HV0_SADR)     
    )
  i2c_master_slave0 
    (
     .wb_clk_i			     (wb_clk),
     .wb_rst_i			     (wb_rst),
     .arst_i			     (wb_rst),
     .wb_adr_i			     (wbs_d_i2c0_adr_i[i2c_0_wb_adr_width-1:0]),
     .wb_dat_i			     (wbs_d_i2c0_dat_i),
     .wb_we_i			     (wbs_d_i2c0_we_i ),
     .wb_cyc_i			     (wbs_d_i2c0_cyc_i),
     .wb_stb_i			     (wbs_d_i2c0_stb_i),    
     .wb_dat_o			     (wbs_d_i2c0_dat_o),
     .wb_ack_o			     (wbs_d_i2c0_ack_o),
     .scl_pad_i		             (i2c0_scl_io     ),
     .scl_pad_o		             (scl0_pad_o	 ),
     .scl_padoen_o		     (scl0_padoen_o	 ),
     .sda_pad_i		             (i2c0_sda_io 	 ),
     .sda_pad_o		             (sda0_pad_o	 ),
     .sda_padoen_o		     (sda0_padoen_o	 ),
      
      // Interrupt
     .wb_inta_o		             (i2c0_irq)
    
      );

   assign wbs_d_i2c0_err_o = 0;
   assign wbs_d_i2c0_rty_o = 0;

   // i2c phy lines
   assign i2c0_scl_io = scl0_padoen_o ? 1'bz : scl0_pad_o;  
   assign i2c0_sda_io = sda0_padoen_o ? 1'bz : sda0_pad_o;  


   ////////////////////////////////////////////////////////////////////////
`else // !`ifdef I2C0

   assign wbs_d_i2c0_dat_o = 0;
   assign wbs_d_i2c0_ack_o = 0;
   assign wbs_d_i2c0_err_o = 0;
   assign wbs_d_i2c0_rty_o = 0;

   ////////////////////////////////////////////////////////////////////////
`endif // !`ifdef I2C0   

`ifdef I2C1
   ////////////////////////////////////////////////////////////////////////
   //
   // i2c controller 1
   // 
   ////////////////////////////////////////////////////////////////////////

   //
   // Wires
   //
   wire 			     i2c1_irq;
   wire 			     scl1_pad_o;
   wire 			     scl1_padoen_o;
   wire 			     sda1_pad_o;
   wire 			     sda1_padoen_o;

   i2c_master_slave
    #
    (
     .DEFAULT_SLAVE_ADDR(HV1_SADR)     
    )
   i2c_master_slave1 
     (
      .wb_clk_i			     (wb_clk),
      .wb_rst_i			     (wb_rst),
      .arst_i			     (wb_rst),
      .wb_adr_i			     (wbs_d_i2c1_adr_i[i2c_1_wb_adr_width-1:0]),
      .wb_dat_i			     (wbs_d_i2c1_dat_i),
      .wb_we_i			     (wbs_d_i2c1_we_i ),
      .wb_cyc_i			     (wbs_d_i2c1_cyc_i),
      .wb_stb_i			     (wbs_d_i2c1_stb_i),    
      .wb_dat_o			     (wbs_d_i2c1_dat_o),
      .wb_ack_o			     (wbs_d_i2c1_ack_o),
      .scl_pad_i		     (i2c1_scl_io     ),
      .scl_pad_o		     (scl1_pad_o	 ),
      .scl_padoen_o		     (scl1_padoen_o	 ),
      .sda_pad_i		     (i2c1_sda_io 	 ),
      .sda_pad_o		     (sda1_pad_o	 ),
      .sda_padoen_o		     (sda1_padoen_o	 ),
      
      // Interrupt
      .wb_inta_o		     (i2c1_irq)
    
      );

   assign wbs_d_i2c1_err_o = 0;
   assign wbs_d_i2c1_rty_o = 0;

   // i2c phy lines
   assign i2c1_scl_io = scl1_padoen_o ? 1'bz : scl1_pad_o;  
   assign i2c1_sda_io = sda1_padoen_o ? 1'bz : sda1_pad_o;  

   ////////////////////////////////////////////////////////////////////////
`else // !`ifdef I2C1   

   assign wbs_d_i2c1_dat_o = 0;
   assign wbs_d_i2c1_ack_o = 0;
   assign wbs_d_i2c1_err_o = 0;
   assign wbs_d_i2c1_rty_o = 0;

   ////////////////////////////////////////////////////////////////////////
`endif // !`ifdef I2C1   

`ifdef GPIO0
   ////////////////////////////////////////////////////////////////////////
   //
   // GPIO 0
   // 
   ////////////////////////////////////////////////////////////////////////

   gpio gpio0
     (
      // GPIO bus
      .gpio_io				(gpio0_io[gpio0_io_width-1:0]),
      // Wishbone slave interface
      .wb_adr_i				(wbs_d_gpio0_adr_i[gpio0_wb_adr_width-1:0]),
      .wb_dat_i				(wbs_d_gpio0_dat_i),
      .wb_we_i				(wbs_d_gpio0_we_i),
      .wb_cyc_i				(wbs_d_gpio0_cyc_i),
      .wb_stb_i				(wbs_d_gpio0_stb_i),
      .wb_cti_i				(wbs_d_gpio0_cti_i),
      .wb_bte_i				(wbs_d_gpio0_bte_i),
      .wb_dat_o				(wbs_d_gpio0_dat_o),
      .wb_ack_o				(wbs_d_gpio0_ack_o),
      .wb_err_o				(wbs_d_gpio0_err_o),
      .wb_rty_o				(wbs_d_gpio0_rty_o),
      
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst)
      );

   defparam gpio0.gpio_io_width = gpio0_io_width;
   defparam gpio0.gpio_dir_reset_val = gpio0_dir_reset_val;
   defparam gpio0.gpio_o_reset_val = gpio0_o_reset_val;

   ////////////////////////////////////////////////////////////////////////
`else // !`ifdef GPIO0
   assign wbs_d_gpio0_dat_o = 0;
   assign wbs_d_gpio0_ack_o = 0;
   assign wbs_d_gpio0_err_o = 0;
   assign wbs_d_gpio0_rty_o = 0;
   ////////////////////////////////////////////////////////////////////////
`endif // !`ifdef GPIO0
   
   ////////////////////////////////////////////////////////////////////////
   //
   // OR1200 Interrupt assignment
   // 
   ////////////////////////////////////////////////////////////////////////
   
   assign cpu_irq[0] = 0; // Non-maskable inside OR1200
   assign cpu_irq[1] = 0; // Non-maskable inside OR1200
`ifdef UART0
   assign cpu_irq[2] = uart0_irq;
`else   
   assign cpu_irq[2] = 0;
`endif
   assign cpu_irq[3] = 0;
`ifdef ETH0
   assign cpu_irq[4] = eth0_irq;
`else
   assign cpu_irq[4] = 0;
`endif
   assign cpu_irq[5] = 0;
`ifdef SPI0
   assign cpu_irq[6] = spi0_irq;
`else   
   assign cpu_irq[6] = 0;
`endif
   assign cpu_irq[7] = 0;
   assign cpu_irq[8] = 0;
   assign cpu_irq[9] = 0;
`ifdef I2C0
   assign cpu_irq[10] = i2c0_irq;
`else   
   assign cpu_irq[10] = 0;
`endif
`ifdef I2C1
   assign cpu_irq[11] = i2c1_irq;
`else   
   assign cpu_irq[11] = 0;
`endif   
   assign cpu_irq[12] = 0;
   assign cpu_irq[13] = 0;
   assign cpu_irq[14] = 0;
   assign cpu_irq[15] = 0;
   assign cpu_irq[16] = 0;
   assign cpu_irq[17] = 0;
   assign cpu_irq[18] = 0;
   assign cpu_irq[19] = 0;
   assign cpu_irq[20] = 0;
   assign cpu_irq[21] = 0;
   assign cpu_irq[22] = 0;
   assign cpu_irq[23] = 0;
   assign cpu_irq[24] = 0;
   assign cpu_irq[25] = 0;
   assign cpu_irq[26] = 0;
   assign cpu_irq[27] = 0;
   assign cpu_irq[28] = 0;
   assign cpu_irq[29] = 0;
   assign cpu_irq[30] = 0;


   // debug output
   always @*
     begin
	case(switches)
	  8'h0: begin
	     leds = {6'd0,wb_rst,rst_i};
	     
	  end
	  8'h1: begin
	     leds = {cellram_adv_n_o,cellram_ce_n_o,cellram_clk_o,cellram_oe_n_o,
                     cellram_we_n_o,cellram_cre_o,cellram_ub_n_o,cellram_lb_n_o};
	  end
	  8'h2: begin
	     leds = {or1k_dbg_stall_i,or1k_dbg_bp_o,
		     wbm_i_or12_err_i, wbm_d_or12_err_i,
		     wbm_d_or12_stb_o,wbm_d_or12_cyc_o,
		     wbm_i_or12_stb_o,wbm_i_or12_cyc_o};
	  end
	  default:
	    leds = switches;
	endcase // case (switches)
	
     end

   
endmodule // orpsoc_top


