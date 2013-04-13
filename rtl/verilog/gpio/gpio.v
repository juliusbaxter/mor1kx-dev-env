//////////////////////////////////////////////////////////////////////
////                                                              ////
////  WISHBONE General-Purpose I/O                                ////
////                                                              ////
////  This file is part of the GPIO project                       ////
////  http://www.opencores.org/cores/gpio/                        ////
////                                                              ////
////  Description                                                 ////
////  Implementation of GPIO IP core according to                 ////
////  GPIO IP core specification document.                        ////
////                                                              ////
////  To Do:                                                      ////
////   Nothing                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on


//
// Strict 32-bit WISHBONE access
//
// If this one is defined, all WISHBONE accesses must be 32-bit. If it is
// not defined, err_o is asserted whenever 8- or 16-bit access is made.
// Undefine it if you need to save some area.
//
// By default it is defined.
//
`define GPIO_STRICT_32BIT_ACCESS
//
`ifdef GPIO_STRICT_32BIT_ACCESS
`else
// added by gorand :
// if GPIO_STRICT_32BIT_ACCESS is not defined,
// depending on number of gpio I/O lines, the following are defined :
// if the number of I/O lines is in range 1-8,   GPIO_WB_BYTES1 is defined,
// if the number of I/O lines is in range 9-16,  GPIO_WB_BYTES2 is defined,
// if the number of I/O lines is in range 17-24, GPIO_WB_BYTES3 is defined,
// if the number of I/O lines is in range 25-32, GPIO_WB_BYTES4 is defined,

//`define GPIO_WB_BYTES4
//`define GPIO_WB_BYTES3
//`define GPIO_WB_BYTES2
//`define GPIO_WB_BYTES1

`endif

//
// WISHBONE address bits used for full decoding of GPIO registers.
//
`define GPIO_ADDRHH 7
`define GPIO_ADDRHL 6
`define GPIO_ADDRLH 1
`define GPIO_ADDRLL 0

//
// Bits of WISHBONE address used for partial decoding of GPIO registers.
//
// Default 5:2.
//
`define GPIO_OFS_BITS	`GPIO_ADDRHL-1:`GPIO_ADDRLH+1

//
// Addresses of GPIO registers
//
// To comply with GPIO IP core specification document they must go from
// address 0 to address 0x18 in the following order: RGPIO_IN, RGPIO_OUT,
// RGPIO_OE, RGPIO_INTE, RGPIO_PTRIG, RGPIO_AUX and RGPIO_CTRL
//
// If particular register is not needed, it's address definition can be omitted
// and the register will not be implemented. Instead a fixed default value will
// be used.
//
`define GPIO_RGPIO_IN		  4'h0	// Address 0x00
`define GPIO_RGPIO_OUT		4'h1	// Address 0x04
`define GPIO_RGPIO_OE		  4'h2	// Address 0x08
`define GPIO_RGPIO_INTE		4'h3	// Address 0x0c
`define GPIO_RGPIO_PTRIG	4'h4	// Address 0x10
`define GPIO_RGPIO_AUX		4'h5	// Address 0x14
`define GPIO_RGPIO_CTRL		4'h6	// Address 0x18
`define GPIO_RGPIO_INTS		4'h7	// Address 0x1c

//
// Default values for unimplemented GPIO registers
//
`define GPIO_DEF_RGPIO_IN	{GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_OUT	{GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_OE	{GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_INTE	{GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_PTRIG	{GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_AUX	{GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_CTRL	{GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_ECLK     {GPIO_WIDTH{1'b0}}
`define GPIO_DEF_RGPIO_NEC      {GPIO_WIDTH{1'b0}}


//
// RGPIO_CTRL bits
//
// To comply with the GPIO IP core specification document they must go from
// bit 0 to bit 1 in the following order: INTE, INT
//
`define GPIO_RGPIO_CTRL_INTE		0
`define GPIO_RGPIO_CTRL_INTS		1

module gpio
  #(
    parameter WB_DATA_WIDTH = 32,
    parameter WB_ADDR_WIDTH = `GPIO_ADDRHH+1,
    parameter GPIO_WIDTH = 32,
    parameter USE_IO_PAD_CLK = "DISABLED",
    parameter REGISTER_GPIO_OUTPUTS = "DISABLED",
    parameter REGISTER_GPIO_INPUTS = "DISABLED"
    )
(
	// WISHBONE Interface
	wb_clk_i, wb_rst_i, wb_cyc_i, wb_adr_i, wb_dat_i, wb_sel_i, wb_we_i, wb_stb_i,
	wb_dat_o, wb_ack_o, wb_err_o, wb_inta_o,

	// Auxiliary inputs interface
	aux_i,

	// External GPIO Interface
	ext_pad_i, ext_pad_o, ext_padoe_o

);


   
//
// WISHBONE Interface
//
input             wb_clk_i;	// Clock
input             wb_rst_i;	// Reset
input             wb_cyc_i;	// cycle valid input
input   [WB_ADDR_WIDTH-1:0]	wb_adr_i;	// address bus inputs
input   [WB_DATA_WIDTH-1:0]	wb_dat_i;	// input data bus
input	  [3:0]     wb_sel_i;	// byte select inputs
input             wb_we_i;	// indicates write transfer
input             wb_stb_i;	// strobe input
output  [WB_DATA_WIDTH-1:0]  wb_dat_o;	// output data bus
output            wb_ack_o;	// normal termination
output            wb_err_o;	// termination w/ error
output            wb_inta_o;	// Interrupt request output

// Auxiliary Inputs Interface
input	  [GPIO_WIDTH-1:0]  aux_i;		// Auxiliary inputs
//
// External GPIO Interface
//
input   [GPIO_WIDTH-1:0]  ext_pad_i;	// GPIO Inputs

output  [GPIO_WIDTH-1:0]  ext_pad_o;	// GPIO Outputs
output  [GPIO_WIDTH-1:0]  ext_padoe_o;	// GPIO output drivers enables


//
// GPIO Input Register (or no register)
//
`ifdef GPIO_RGPIO_IN
reg	[GPIO_WIDTH-1:0]	rgpio_in;	// RGPIO_IN register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_in;	// No register
`endif

//
// GPIO Output Register (or no register)
//
`ifdef GPIO_RGPIO_OUT
reg	[GPIO_WIDTH-1:0]	rgpio_out;	// RGPIO_OUT register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_out;	// No register
`endif

//
// GPIO Output Driver Enable Register (or no register)
//
`ifdef GPIO_RGPIO_OE
reg	[GPIO_WIDTH-1:0]	rgpio_oe;	// RGPIO_OE register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_oe;	// No register
`endif

//
// GPIO Interrupt Enable Register (or no register)
//
`ifdef GPIO_RGPIO_INTE
reg	[GPIO_WIDTH-1:0]	rgpio_inte;	// RGPIO_INTE register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_inte;	// No register
`endif

//
// GPIO Positive edge Triggered Register (or no register)
//
`ifdef GPIO_RGPIO_PTRIG
reg	[GPIO_WIDTH-1:0]	rgpio_ptrig;	// RGPIO_PTRIG register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_ptrig;	// No register
`endif

//
// GPIO Auxiliary select Register (or no register)
//
`ifdef GPIO_RGPIO_AUX
reg	[GPIO_WIDTH-1:0]	rgpio_aux;	// RGPIO_AUX register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_aux;	// No register
`endif

//
// GPIO Control Register (or no register)
//
`ifdef GPIO_RGPIO_CTRL
reg	[1:0]		rgpio_ctrl;	// RGPIO_CTRL register
`else
wire	[1:0]		rgpio_ctrl;	// No register
`endif

//
// GPIO Interrupt Status Register (or no register)
//
`ifdef GPIO_RGPIO_INTS
reg	[GPIO_WIDTH-1:0]	rgpio_ints;	// RGPIO_INTS register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_ints;	// No register
`endif

//
// GPIO Enable Clock  Register (or no register)
//
`ifdef GPIO_RGPIO_ECLK
reg	[GPIO_WIDTH-1:0]	rgpio_eclk;	// RGPIO_ECLK register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_eclk;	// No register
`endif

//
// GPIO Active Negative Edge  Register (or no register)
//
`ifdef GPIO_RGPIO_NEC
reg	[GPIO_WIDTH-1:0]	rgpio_nec;	// RGPIO_NEC register
`else
wire	[GPIO_WIDTH-1:0]	rgpio_nec;	// No register
`endif


wire [GPIO_WIDTH-1:0]  ext_pad_s ;




//
// Internal wires & regs
//
wire            rgpio_out_sel;  // RGPIO_OUT select
wire            rgpio_oe_sel; // RGPIO_OE select
wire            rgpio_inte_sel; // RGPIO_INTE select
wire            rgpio_ptrig_sel;// RGPIO_PTRIG select
wire            rgpio_aux_sel;  // RGPIO_AUX select
wire            rgpio_ctrl_sel; // RGPIO_CTRL select
wire            rgpio_ints_sel; // RGPIO_INTS select
wire            rgpio_eclk_sel ;
wire            rgpio_nec_sel ;
wire            full_decoding;  // Full address decoding qualification
wire  [GPIO_WIDTH-1:0]  in_muxed; // Muxed inputs
wire            wb_ack;   // WB Acknowledge
wire            wb_err;   // WB Error
wire            wb_inta;  // WB Interrupt
reg   [WB_DATA_WIDTH-1:0]  wb_dat;   // WB Data out
reg             wb_ack_o; // WB Acknowledge
reg             wb_err_o; // WB Error
reg             wb_inta_o;  // WB Interrupt
reg   [WB_DATA_WIDTH-1:0]  wb_dat_o; // WB Data out

wire  [GPIO_WIDTH-1:0]  out_pad;  // GPIO Outputs



//
// All WISHBONE transfer terminations are successful except when:
// a) full address decoding is enabled and address doesn't match
//    any of the GPIO registers
// b) wb_sel_i evaluation is enabled and one of the wb_sel_i inputs is zero
//

//
// WB Acknowledge
//
assign wb_ack = wb_cyc_i & wb_stb_i & !wb_err_o;

always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_ack_o <=  1'b0;
	else
		wb_ack_o <=  wb_ack & ~wb_ack_o & (!wb_err) ;

//
// WB Error
//
`ifdef GPIO_STRICT_32BIT_ACCESS
assign wb_err = wb_cyc_i & wb_stb_i & (!full_decoding | (wb_sel_i != 4'b1111));
`else
assign wb_err = wb_cyc_i & wb_stb_i & !full_decoding;
`endif

always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_err_o <=  1'b0;
	else
		wb_err_o <=  wb_err & ~wb_err_o;

//
// Full address decoder
//
`ifdef GPIO_FULL_DECODE
assign full_decoding = (wb_adr_i[`GPIO_ADDRHH:`GPIO_ADDRHL] == {`GPIO_ADDRHH-`GPIO_ADDRHL+1{1'b0}}) &
			(wb_adr_i[`GPIO_ADDRLH:`GPIO_ADDRLL] == {`GPIO_ADDRLH-`GPIO_ADDRLL+1{1'b0}});
`else
assign full_decoding = 1'b1;
`endif

//
// GPIO registers address decoder
//
`ifdef GPIO_RGPIO_OUT
assign rgpio_out_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_OUT) & full_decoding;
`endif
`ifdef GPIO_RGPIO_OE
assign rgpio_oe_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_OE) & full_decoding;
`endif
`ifdef GPIO_RGPIO_INTE
assign rgpio_inte_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_INTE) & full_decoding;
`endif
`ifdef GPIO_RGPIO_PTRIG
assign rgpio_ptrig_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_PTRIG) & full_decoding;
`endif
`ifdef GPIO_RGPIO_AUX
assign rgpio_aux_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_AUX) & full_decoding;
`endif
`ifdef GPIO_RGPIO_CTRL
assign rgpio_ctrl_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_CTRL) & full_decoding;
`endif
`ifdef GPIO_RGPIO_INTS
assign rgpio_ints_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_INTS) & full_decoding;
`endif
`ifdef GPIO_RGPIO_ECLK
assign rgpio_eclk_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_ECLK) & full_decoding;
`endif
`ifdef GPIO_RGPIO_NEC
assign rgpio_nec_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`GPIO_OFS_BITS] == `GPIO_RGPIO_NEC) & full_decoding;
`endif


//
// Write to RGPIO_CTRL or update of RGPIO_CTRL[INT] bit
//
`ifdef GPIO_RGPIO_CTRL
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_ctrl <=  2'b0;
	else if (rgpio_ctrl_sel && wb_we_i)
		rgpio_ctrl <=  wb_dat_i[1:0];
	else if (rgpio_ctrl[`GPIO_RGPIO_CTRL_INTE])
		rgpio_ctrl[`GPIO_RGPIO_CTRL_INTS] <=  rgpio_ctrl[`GPIO_RGPIO_CTRL_INTS] | wb_inta_o;
`else
assign rgpio_ctrl = 2'h01;	// RGPIO_CTRL[EN] = 1
`endif

//
// Write to RGPIO_OUT
//
`ifdef GPIO_RGPIO_OUT
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_out <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_out_sel && wb_we_i)
    begin
`ifdef GPIO_STRICT_32BIT_ACCESS
		rgpio_out <=  wb_dat_i[GPIO_WIDTH-1:0];
`endif

`ifdef GPIO_WB_BYTES4
     if ( wb_sel_i [3] == 1'b1 )
       rgpio_out [GPIO_WIDTH-1:24] <=  wb_dat_i [GPIO_WIDTH-1:24] ;
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_out [23:16] <=  wb_dat_i [23:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_out [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_out [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES3
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_out [GPIO_WIDTH-1:16] <=  wb_dat_i [GPIO_WIDTH-1:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_out [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_out [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES2
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_out [GPIO_WIDTH-1:8] <=  wb_dat_i [GPIO_WIDTH-1:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_out [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES1
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_out [GPIO_WIDTH-1:0] <=  wb_dat_i [GPIO_WIDTH-1:0] ;
`endif
   end

`else
assign rgpio_out = `GPIO_DEF_RGPIO_OUT;	// RGPIO_OUT = 0x0
`endif

//
// Write to RGPIO_OE.
//
`ifdef GPIO_RGPIO_OE
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_oe <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_oe_sel && wb_we_i)
  begin
`ifdef GPIO_STRICT_32BIT_ACCESS
		rgpio_oe <=  wb_dat_i[GPIO_WIDTH-1:0];
`endif

`ifdef GPIO_WB_BYTES4
     if ( wb_sel_i [3] == 1'b1 )
       rgpio_oe [GPIO_WIDTH-1:24] <=  wb_dat_i [GPIO_WIDTH-1:24] ;
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_oe [23:16] <=  wb_dat_i [23:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_oe [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_oe [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES3
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_oe [GPIO_WIDTH-1:16] <=  wb_dat_i [GPIO_WIDTH-1:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_oe [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_oe [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES2
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_oe [GPIO_WIDTH-1:8] <=  wb_dat_i [GPIO_WIDTH-1:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_oe [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES1
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_oe [GPIO_WIDTH-1:0] <=  wb_dat_i [GPIO_WIDTH-1:0] ;
`endif
   end

`else
assign rgpio_oe = `GPIO_DEF_RGPIO_OE;	// RGPIO_OE = 0x0
`endif

//
// Write to RGPIO_INTE
//
`ifdef GPIO_RGPIO_INTE
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_inte <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_inte_sel && wb_we_i)
  begin
`ifdef GPIO_STRICT_32BIT_ACCESS
		rgpio_inte <=  wb_dat_i[GPIO_WIDTH-1:0];
`endif

`ifdef GPIO_WB_BYTES4
     if ( wb_sel_i [3] == 1'b1 )
       rgpio_inte [GPIO_WIDTH-1:24] <=  wb_dat_i [GPIO_WIDTH-1:24] ;
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_inte [23:16] <=  wb_dat_i [23:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_inte [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_inte [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES3
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_inte [GPIO_WIDTH-1:16] <=  wb_dat_i [GPIO_WIDTH-1:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_inte [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_inte [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES2
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_inte [GPIO_WIDTH-1:8] <=  wb_dat_i [GPIO_WIDTH-1:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_inte [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES1
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_inte [GPIO_WIDTH-1:0] <=  wb_dat_i [GPIO_WIDTH-1:0] ;
`endif
   end


`else
assign rgpio_inte = `GPIO_DEF_RGPIO_INTE;	// RGPIO_INTE = 0x0
`endif

//
// Write to RGPIO_PTRIG
//
`ifdef GPIO_RGPIO_PTRIG
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_ptrig <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_ptrig_sel && wb_we_i)
  begin
`ifdef GPIO_STRICT_32BIT_ACCESS
		rgpio_ptrig <=  wb_dat_i[GPIO_WIDTH-1:0];
`endif

`ifdef GPIO_WB_BYTES4
     if ( wb_sel_i [3] == 1'b1 )
       rgpio_ptrig [GPIO_WIDTH-1:24] <=  wb_dat_i [GPIO_WIDTH-1:24] ;
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_ptrig [23:16] <=  wb_dat_i [23:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_ptrig [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_ptrig [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES3
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_ptrig [GPIO_WIDTH-1:16] <=  wb_dat_i [GPIO_WIDTH-1:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_ptrig [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_ptrig [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES2
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_ptrig [GPIO_WIDTH-1:8] <=  wb_dat_i [GPIO_WIDTH-1:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_ptrig [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES1
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_ptrig [GPIO_WIDTH-1:0] <=  wb_dat_i [GPIO_WIDTH-1:0] ;
`endif
   end
    
`else
assign rgpio_ptrig = `GPIO_DEF_RGPIO_PTRIG;	// RGPIO_PTRIG = 0x0
`endif

//
// Write to RGPIO_AUX
//
`ifdef GPIO_RGPIO_AUX
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_aux <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_aux_sel && wb_we_i)
  begin
`ifdef GPIO_STRICT_32BIT_ACCESS
		rgpio_aux <=  wb_dat_i[GPIO_WIDTH-1:0];
`endif

`ifdef GPIO_WB_BYTES4
     if ( wb_sel_i [3] == 1'b1 )
       rgpio_aux [GPIO_WIDTH-1:24] <=  wb_dat_i [GPIO_WIDTH-1:24] ;
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_aux [23:16] <=  wb_dat_i [23:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_aux [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_aux [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES3
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_aux [GPIO_WIDTH-1:16] <=  wb_dat_i [GPIO_WIDTH-1:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_aux [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_aux [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES2
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_aux [GPIO_WIDTH-1:8] <=  wb_dat_i [GPIO_WIDTH-1:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_aux [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES1
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_aux [GPIO_WIDTH-1:0] <=  wb_dat_i [GPIO_WIDTH-1:0] ;
`endif
   end

`else
assign rgpio_aux = `GPIO_DEF_RGPIO_AUX;	// RGPIO_AUX = 0x0
`endif


//
// Write to RGPIO_ECLK
//
`ifdef GPIO_RGPIO_ECLK
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_eclk <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_eclk_sel && wb_we_i)
  begin
`ifdef GPIO_STRICT_32BIT_ACCESS
		rgpio_eclk <=  wb_dat_i[GPIO_WIDTH-1:0];
`endif

`ifdef GPIO_WB_BYTES4
     if ( wb_sel_i [3] == 1'b1 )
       rgpio_eclk [GPIO_WIDTH-1:24] <=  wb_dat_i [GPIO_WIDTH-1:24] ;
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_eclk [23:16] <=  wb_dat_i [23:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_eclk [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_eclk [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES3
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_eclk [GPIO_WIDTH-1:16] <=  wb_dat_i [GPIO_WIDTH-1:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_eclk [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_eclk [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES2
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_eclk [GPIO_WIDTH-1:8] <=  wb_dat_i [GPIO_WIDTH-1:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_eclk [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES1
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_eclk [GPIO_WIDTH-1:0] <=  wb_dat_i [GPIO_WIDTH-1:0] ;
`endif
   end


`else
assign rgpio_eclk = `GPIO_DEF_RGPIO_ECLK;	// RGPIO_ECLK = 0x0
`endif



//
// Write to RGPIO_NEC
//
`ifdef GPIO_RGPIO_NEC
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_nec <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_nec_sel && wb_we_i)
  begin
`ifdef GPIO_STRICT_32BIT_ACCESS
		rgpio_nec <=  wb_dat_i[GPIO_WIDTH-1:0];
`endif

`ifdef GPIO_WB_BYTES4
     if ( wb_sel_i [3] == 1'b1 )
       rgpio_nec [GPIO_WIDTH-1:24] <=  wb_dat_i [GPIO_WIDTH-1:24] ;
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_nec [23:16] <=  wb_dat_i [23:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_nec [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_nec [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES3
     if ( wb_sel_i [2] == 1'b1 )
       rgpio_nec [GPIO_WIDTH-1:16] <=  wb_dat_i [GPIO_WIDTH-1:16] ;
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_nec [15:8] <=  wb_dat_i [15:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_nec [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES2
     if ( wb_sel_i [1] == 1'b1 )
       rgpio_nec [GPIO_WIDTH-1:8] <=  wb_dat_i [GPIO_WIDTH-1:8] ;
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_nec [7:0] <=  wb_dat_i [7:0] ;
`endif
`ifdef GPIO_WB_BYTES1
     if ( wb_sel_i [0] == 1'b1 )
       rgpio_nec [GPIO_WIDTH-1:0] <=  wb_dat_i [GPIO_WIDTH-1:0] ;
`endif
   end


`else
assign rgpio_nec = `GPIO_DEF_RGPIO_NEC;	// RGPIO_NEC = 0x0
`endif

   generate
      if (REGISTER_GPIO_INPUTS=="ENABLED")
	begin
	   //
	   // synchronize inputs to system clock
	   //
	   reg  [GPIO_WIDTH-1:0]  sync, ext_pad_sync;
	   
	   always @(posedge wb_clk_i or posedge wb_rst_i)
	     if (wb_rst_i) begin
		sync      <=  {GPIO_WIDTH{1'b0}} ; 
		ext_pad_sync <=  {GPIO_WIDTH{1'b0}} ; 
	     end else begin
		sync      <=  ext_pad_i  ; 
		ext_pad_sync <=  sync       ; 
	     end
	   assign ext_pad_s = ext_pad_sync;
	end // if (REGISTER_GPIO_INPUTS=="ENABLED")
      else
	// Pass straight through
	assign  ext_pad_s = ext_pad_i;
   endgenerate
   
  
//
// Latch into RGPIO_IN
//
`ifdef GPIO_RGPIO_IN
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_in <=  {GPIO_WIDTH{1'b0}};
	else
		rgpio_in <=  in_muxed;
`else
assign rgpio_in = in_muxed;
`endif


assign  in_muxed  = ext_pad_s ;

//
// Mux all registers when doing a read of GPIO registers
//
always @(wb_adr_i or rgpio_in or rgpio_out or rgpio_oe or rgpio_inte or
		rgpio_ptrig or rgpio_aux or rgpio_ctrl or rgpio_ints or rgpio_eclk or rgpio_nec)
	case (wb_adr_i[`GPIO_OFS_BITS])	// synopsys full_case parallel_case
  `ifdef GPIO_RGPIO_OUT
  	`GPIO_RGPIO_OUT: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_out;
		end
  `endif
  `ifdef GPIO_RGPIO_OE
		`GPIO_RGPIO_OE: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_oe;
		end
  `endif
  `ifdef GPIO_RGPIO_INTE
		`GPIO_RGPIO_INTE: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_inte;
		end
  `endif
  `ifdef GPIO_RGPIO_PTRIG
		`GPIO_RGPIO_PTRIG: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_ptrig;
		end
  `endif
  `ifdef GPIO_RGPIO_NEC
		`GPIO_RGPIO_NEC: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_nec;
		end
  `endif
  `ifdef GPIO_RGPIO_ECLK
		`GPIO_RGPIO_ECLK: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_eclk;
		end
  `endif
  `ifdef GPIO_RGPIO_AUX
		`GPIO_RGPIO_AUX: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_aux;
		end
  `endif
  `ifdef GPIO_RGPIO_CTRL
		`GPIO_RGPIO_CTRL: begin
			wb_dat[1:0] = rgpio_ctrl;
			wb_dat[WB_DATA_WIDTH-1:2] = {WB_DATA_WIDTH-2{1'b0}};
		end
  `endif
  `ifdef GPIO_RGPIO_INTS
		`GPIO_RGPIO_INTS: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_ints;
		end
  `endif
		default: begin
			wb_dat[WB_DATA_WIDTH-1:0] = rgpio_in;
		end
	endcase

always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_o <=  {WB_DATA_WIDTH{1'b0}};
	else
		wb_dat_o <=  wb_dat;

//
// RGPIO_INTS
//
`ifdef GPIO_RGPIO_INTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		rgpio_ints <=  {GPIO_WIDTH{1'b0}};
	else if (rgpio_ints_sel && wb_we_i)
		rgpio_ints <=  wb_dat_i[GPIO_WIDTH-1:0];
	else if (rgpio_ctrl[`GPIO_RGPIO_CTRL_INTE])
		rgpio_ints <=  (rgpio_ints | ((in_muxed ^ rgpio_in) & ~(in_muxed ^ rgpio_ptrig)) & rgpio_inte);
`else
assign rgpio_ints = (rgpio_ints | ((in_muxed ^ rgpio_in) & ~(in_muxed ^ rgpio_ptrig)) & rgpio_inte);
`endif

//
// Generate interrupt request
//
assign wb_inta = |rgpio_ints ? rgpio_ctrl[`GPIO_RGPIO_CTRL_INTE] : 1'b0;

always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_inta_o <=  1'b0;
	else
		wb_inta_o <=  wb_inta;

//
// Output enables are RGPIO_OE bits
//
assign ext_padoe_o = rgpio_oe;

//
// Generate GPIO outputs
//
assign out_pad = rgpio_out & ~rgpio_aux | aux_i & rgpio_aux;

//
// Optional registration of GPIO outputs
//
   generate
      if (REGISTER_GPIO_OUTPUTS=="ENABLED")
	begin
	   reg   [GPIO_WIDTH-1:0]  ext_pad_o;  // GPIO Outputs
	   always @(posedge wb_clk_i or posedge wb_rst_i)
	     if (wb_rst_i)
	       ext_pad_o <=  {GPIO_WIDTH{1'b0}};
	     else
	       ext_pad_o <=  out_pad;
	end
      else
	assign ext_pad_o = out_pad;
   endgenerate
   
endmodule

