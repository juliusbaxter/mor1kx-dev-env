//////////////////////////////////////////////////////////////////////
///                                                               //// 
/// ORPSoC Nexys3 testbench                                       ////
///                                                               ////
/// Instantiate ORPSoC, monitors, provide stimulus                ////
///                                                               ////
/// Julius Baxter, julius@opencores.org                           ////
///                                                               ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009, 2010 Authors and OPENCORES.ORG           ////
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
`include "orpsoc-testbench-defines.v"
`include "test-defines.v"
`include "timescale.v"
// Xilinx simulation:
`include "glbl.v"

module orpsoc_testbench;

   // Clock and reset signal registers
   reg clk = 0;
   reg rst_n = 1; // Active LOW
   
   always
     #((`BOARD_CLOCK_PERIOD)/2) clk <= ~clk;

   wire clk_n, clk_p;
   assign clk_p = clk;
   assign clk_n = ~clk;

   
   // Reset, ACTIVE LOW
   initial 
     begin
	#1;
	repeat (32) @(negedge clk)
	  rst_n <= 1;
	repeat (32) @(negedge clk)
	  rst_n <= 0;
	repeat (32) @(negedge clk)
	  rst_n <= 1;
     end

   // Include design parameters file
`include "orpsoc-params.v"

   // Pullup bus for I2C
   tri1 i2c_scl, i2c_sda;
   
`ifdef JTAG_DEBUG
   wire tdo_pad_o;
   wire tck_pad_i;
   wire tms_pad_i;
   wire tdi_pad_i;
`endif   
`ifdef UART0
   wire uart0_stx_pad_o;
   wire uart0_srx_pad_i;
`endif
`ifdef GPIO0
   wire [gpio0_io_width-1:0] gpio0_io;
`endif
`ifdef SPI0
   wire 		     spi0_mosi_o;
   wire 		     spi0_miso_i;
   wire 		     spi0_sck_o;
   wire 		     spi0_hold_n_o;
   wire 		     spi0_w_n_o;   
   wire [spi0_ss_width-1:0]  spi0_ss_o;
`endif
`ifdef ETH0
   wire 		     mtx_clk_o;		
   wire [3:0] 		     ethphy_mii_tx_d;	
   wire 		     ethphy_mii_tx_en;	
   wire 		     ethphy_mii_tx_err;	
   wire 		     mrx_clk_o;		
   wire [3:0] 		     mrxd_o;			
   wire 		     mrxdv_o;		
   wire 		     mrxerr_o;		
   wire 		     mcoll_o;		
   wire 		     mcrs_o;
   wire 		     ethphy_rst_n;
   wire 		     eth0_mdc_pad_o;
   wire 		     eth0_md_pad_io;
`endif
`ifdef CELLRAM
   wire [15:0] 	     cellram_dq_io;
   wire [23:0] 	     cellram_adr_o;
   wire 	     cellram_adv_n_o;
   wire 	     cellram_ce_n_o;
   wire 	     cellram_clk_o;
   wire 	     cellram_oe_n_o;
   wire 	     cellram_wait_i;
   wire 	     cellram_we_n_o;
   wire 	     cellram_cre_o;
   wire 	     cellram_ub_n_o;
   wire 	     cellram_lb_n_o;
`endif //  `ifdef CELLRAM

`ifdef GATELEVEL_SIM
   orpsoc_top_gl dut
`else   
   orpsoc_top dut
`endif     
     (
`ifdef JTAG_DEBUG          
      .tms_pad_i			(tms_pad_i),
      .tck_pad_i			(tck_pad_i),
      .tdi_pad_i			(tdi_pad_i),
      .tdo_pad_o			(tdo_pad_o),
`endif
`ifdef CELLRAM
      .cellram_dq_io                      (cellram_dq_io),
      .cellram_adr_o                      (cellram_adr_o),
      .cellram_adv_n_o                    (cellram_adv_n_o),
      .cellram_ce_n_o                     (cellram_ce_n_o),
      .cellram_clk_o                      (cellram_clk_o),
      .cellram_oe_n_o                     (cellram_oe_n_o),
      .cellram_wait_i                     (cellram_wait_i),
      .cellram_we_n_o                     (cellram_we_n_o),
      .cellram_cre_o                      (cellram_cre_o),
      .cellram_lb_n_o                     (cellram_lb_n_o),
      .cellram_ub_n_o                     (cellram_ub_n_o),
`endif      
`ifdef UART0      
      .uart0_stx_pad_o			(uart0_stx_pad_o),
      .uart0_srx_pad_i			(uart0_srx_pad_i),
//      .uart0_stx_expheader_pad_o	(uart0_stx_pad_o),
//      .uart0_srx_expheader_pad_i	(uart0_srx_pad_i),
`endif
`ifdef SPI0
      /*
       via STARTUP_VIRTEX5
       .spi0_sck_o			(spi0_sck_o),
       .spi0_miso_i			(spi0_miso_i),
       */
      .spi0_mosi_o			(spi0_mosi_o),
      .spi0_ss_o			(spi0_ss_o),
`endif
`ifdef I2C0
      .i2c0_sda_io			(i2c_sda),
      .i2c0_scl_io			(i2c_scl),
`endif
`ifdef I2C1
      .i2c1_sda_io			(i2c_sda),
      .i2c1_scl_io			(i2c_scl),
`endif
`ifdef GPIO0
      .gpio0_io				(gpio0_io),
`endif
`ifdef ETH0
      .eth0_tx_clk                      (mtx_clk_o),
      .eth0_tx_data                     (ethphy_mii_tx_d),
      .eth0_tx_en                       (ethphy_mii_tx_en),
      .eth0_tx_er                       (ethphy_mii_tx_err),
      .eth0_rx_clk                      (mrx_clk_o),
      .eth0_rx_data                     (mrxd_o),
      .eth0_dv                          (mrxdv_o),
      .eth0_rx_er                       (mrxerr_o),
      .eth0_col                         (mcoll_o),
      .eth0_crs                         (mcrs_o),
      .eth0_rst_n_o                     (ethphy_rst_n),
      .eth0_mdc_pad_o                   (eth0_mdc_pad_o),
      .eth0_md_pad_io                   (eth0_md_pad_io),
`endif //  `ifdef ETH0

      .sys_clk_in                       (clk),

      .rst_i			        (~rst_n)      
      );
`ifdef RTL_SIM
   
`ifdef OR1200
   //
   // Instantiate OR1200 monitor
   //
   or1200_monitor monitor();

`ifndef SIM_QUIET
 `define CPU_ic_top or1200_ic_top
 `define CPU_dc_top or1200_dc_top
   wire 		     ic_en = orpsoc_testbench.dut.or1200_top0.or1200_ic_top.ic_en;
   always @(posedge ic_en)
     $display("Or1200 IC enabled at %t", $time);

   wire 		     dc_en = orpsoc_testbench.dut.or1200_top0.or1200_dc_top.dc_en;
   always @(posedge dc_en)
     $display("Or1200 DC enabled at %t", $time);
`endif
`endif //  `ifdef OR1200

`ifdef MOR1KX
   /* Instantiate debug monitor */
   mor1kx_monitor monitor();
`endif
   
`endif //  `ifdef RTL_SIM

`ifdef JTAG_DEBUG   
 `ifdef VPI_DEBUG
   // Debugging interface
   vpi_debug_module #(.Tck(50)) vpi_dbg
     (
      .tms(tms_pad_i), 
      .tck(tck_pad_i), 
      .tdi(tdi_pad_i), 
      .tdo(tdo_pad_o)
      );
 `else   
   // If no VPI debugging, tie off JTAG inputs
   assign tdi_pad_i = 1;
   assign tck_pad_i = 0;
   assign tms_pad_i = 1;
 `endif // !`ifdef VPI_DEBUG_ENABLE
`endif //  `ifdef JTAG_DEBUG
   
`ifdef SPI0
   // STARTUP_VIRTEX5 module routes these out on the board.
   // So for now just connect directly to the internals here.
   assign spi0_sck_o = dut.spi0_sck_o;
   assign dut.spi0_miso_i = spi0_miso_i;
   
   // SPI flash memory - M25P16 compatible SPI protocol
   AT26DFxxx
     #(.MEMSIZE(2048*1024)) // 2MB flash on ML501
     spi0_flash
     (// Outputs
      .SO					(spi0_miso_i),
      // Inputs
      .CSB					(spi0_ss_o),
      .SCK					(spi0_sck_o),
      .SI					(spi0_mosi_o),
      .WPB					(1'b1)
      );

   
`endif //  `ifdef SPI0

`ifdef ETH0
   
   /* TX/RXes packets and checks them, enabled when ethernet MAC is */
 `include "eth_stim.v"

   eth_phy eth_phy0
     (
      // Outputs
      .mtx_clk_o			(mtx_clk_o),
      .mrx_clk_o			(mrx_clk_o),
      .mrxd_o				(mrxd_o[3:0]),
      .mrxdv_o				(mrxdv_o),
      .mrxerr_o				(mrxerr_o),
      .mcoll_o				(mcoll_o),
      .mcrs_o				(mcrs_o),
      .link_o                           (),
      .speed_o                          (), 
      .duplex_o                         (),
      .smii_clk_i                       (1'b0),
      .smii_sync_i                      (1'b0),
      .smii_rx_o                        (),
      // Inouts
      .md_io				(eth0_md_pad_io),
      // Inputs
 `ifndef ETH0_PHY_RST
      // If no reset out from the design, hook up to the board's active low rst
      .m_rst_n_i			(rst_n),
 `else
      .m_rst_n_i			(ethphy_rst_n),
 `endif      
      .mtxd_i				(ethphy_mii_tx_d[3:0]),
      .mtxen_i				(ethphy_mii_tx_en),
      .mtxerr_i				(ethphy_mii_tx_err),
      .mdc_i				(eth0_mdc_pad_o));

`endif //  `ifdef ETH0

   
`ifdef VCD
   initial
     begin
	
 `ifdef VCD_DELAY
	#(`VCD_DELAY);
 `endif

	// Delay by x insns
 `ifdef VCD_DELAY_INSNS

	#10; // Delay until after the value becomes valid
	while (monitor.insns < `VCD_DELAY_INSNS)
	  @(posedge clk);
	
 `endif	

// `ifdef SIMULATOR_MODELSIM
	// Modelsim can GZip VCDs on the fly if given in the suffix
//  `define VCD_SUFFIX   ".vcd.gz"
// `else
  `define VCD_SUFFIX   ".vcd"
// `endif
	
 `ifndef SIM_QUIET
	$display("* VCD in %s\n", {"../out/",`TEST_NAME_STRING,`VCD_SUFFIX});
 `endif	
	$dumpfile({"../out/",`TEST_NAME_STRING,`VCD_SUFFIX});
 `ifndef VCD_DEPTH
  `define VCD_DEPTH 0
 `endif     
	$dumpvars(`VCD_DEPTH);
	
     end
`endif //  `ifdef VCD
   
   initial 
     begin
`ifndef SIM_QUIET
	$display("\n* Starting simulation of design RTL.\n* Test: %s\n",
		 `TEST_NAME_STRING );
`endif	
	
	
     end // initial begin
   
`ifdef END_TIME
   initial begin
      #(`END_TIME);
 `ifndef SIM_QUIET      
      $display("* Finish simulation due to END_TIME being set at %t", $time);
 `endif      
      $finish;
   end
`endif

`ifdef END_INSNS
   initial begin
      #10
	while (monitor.insns < `END_INSNS)
	  @(posedge clk);
 `ifndef SIM_QUIET      
      $display("* Finish simulation due to END_INSNS count (%d) reached at %t",
	       `END_INSNS, $time);
 `endif
      $finish;
   end
`endif     
   
`ifdef UART0   
   //	
   // UART0 decoder
   //   
   uart_decoder
     #( 
	.uart_baudrate_period_ns(8680) // 115200 baud = period 8.68uS
	)
   uart0_decoder
     (
      .clk(clk),
      .uart_tx(uart0_stx_pad_o)
      );
   
   // Loopback UART lines
   //assign uart0_srx_pad_i = uart0_stx_pad_o;

`endif //  `ifdef UART0

`ifdef CELLRAM
   
  wire [35:0] VCC;  // Supply Voltage
  wire [35:0] VCCQ; // Supply Voltage for I/O Buffers
  wire [35:0] VPP; // Optional Supply Voltage for Fast Program & Erase  
  
   wire       Info;      // Activate/Deactivate info device operation
   assign Info = 1;
   assign VCC = 36'd1700;
   assign VCCQ = 36'd1700;
   assign VPP = 36'd2000;
/*
   x28fxxxp30 cfi_flash(flash_adr_o, 
			flash_dq_io, 
			flash_we_n_o, 
			flash_oe_n_o, 
			flash_ce_n_o, 
			flash_adv_n_o, 
			flash_clk_o, 
			flash_wait_i, 
			1'b1, 
			flash_rst_n_o, 
			VCC, 
			VCCQ, 
			VPP, 
			Info);
  */


   cellram #(.DEBUG(0), .MEM_BITS(25)) // MEM_BITS=25 gives full 16MB memory
     cellram 
     (
      .clk	(cellram_clk_o), 
      .adv_n	(cellram_adv_n_o),
      .cre	(cellram_cre_o), 
      .o_wait	(cellram_wait_i),
      .ce_n	(cellram_ce_n_o),
      .oe_n	(cellram_oe_n_o),
      .we_n	(cellram_we_n_o),
      .lb_n	(cellram_lb_n_o),
      .ub_n	(cellram_ub_n_o),
      .addr	(cellram_adr_o),
      .dq	(cellram_dq_io)
      );

 `ifdef PRELOAD_RAM
   
   always @(posedge rst_n)
     begin
	cellram.preload_mem();
	$display("Loaded cellram");
     end
`endif
   
`endif //  `ifdef CELLRAM
   
endmodule // orpsoc_testbench

// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/orpsoc_top")
// verilog-library-files:()
// verilog-library-extensions:(".v" ".h")
// End:

