set sdc_version 1.7
########  Clock Constraints  ########
create_clock  -name { sys_clk_pad_i } -period 15.625   { sys_clk_pad_i  } 
create_clock  -name { tck_pad_i } -period 50.000  { tck_pad_i  } 
create_clock  -name { eth_clk_pad_i } -period 8.0000  { eth_clk_pad_i  } 
create_clock  -name { smii0/smii_if0/mtx_clk_gen:Q } -period 40.000   { smii0/smii_if0/mtx_clk_gen:Q  } 
create_clock  -name { smii0/smii_if0/mrx_clk_gen:Q } -period 40.000  { smii0/smii_if0/mrx_clk_gen:Q  } 
set_output_delay  -max 3.000 -clock { eth_clk_pad_i }  [get_ports { eth0_smii_sync_pad_o eth0_smii_tx_pad_o }] 
set_output_delay  -min -1.500 -clock { eth_clk_pad_i }  [get_ports { eth0_smii_sync_pad_o eth0_smii_tx_pad_o }] 
########  Specify Asynchronous paths between domains  ########
set_false_path -from [ get_clocks { clkgen0/pll0/Core:GLA }] -to [ get_clocks { clkgen0/pll0/Core:GLB }]
set_false_path -from [ get_clocks { clkgen0/pll0/Core:GLB }] -to [ get_clocks { clkgen0/pll0/Core:GLA }]
########  Input Delay Constraints  ########
set_input_delay  -max 0.8 -clock { clkgen0/pll0/Core:GLA } { sdram_dq_pad_io[*] }
########  Output Delay Constraints  ########
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_dq_pad_io[*] }
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_ras_pad_o }
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_cas_pad_o }
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_we_pad_o }
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_a_pad_o[*] }
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_ba_pad_o[*] }
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_cke_pad_o }
set_output_delay  -max  1.5  -clock { clkgen0/pll0/Core:GLA } { sdram_dqm_pad_o[*] }

