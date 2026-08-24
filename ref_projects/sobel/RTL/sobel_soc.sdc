set_time_format -unit ns -decimal_places 3

create_clock -name "FPGA_CLK1_50" -period 20.000 [get_ports {FPGA_CLK1_50}]
create_clock -name "FPGA_CLK2_50" -period 20.000 [get_ports {FPGA_CLK2_50}]
create_clock -name "FPGA_CLK3_50" -period 20.000 [get_ports {FPGA_CLK3_50}]

derive_pll_clocks -create_base_clocks
derive_clock_uncertainty

# ==============================================================================
set_false_path -from [get_ports {KEY[*]}]  -to *
set_false_path -from [get_ports {SW[*]}]   -to *
set_false_path -from *                     -to [get_ports {LED[*]}]

set_false_path -from [get_ports {altera_reserved_tdi}] -to *
set_false_path -from [get_ports {altera_reserved_tms}] -to *
set_false_path -from * -to [get_ports {altera_reserved_tdo}]
