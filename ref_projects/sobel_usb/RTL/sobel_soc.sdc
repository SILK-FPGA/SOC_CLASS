# 50 MHz board clocks
create_clock -name FPGA_CLK1_50 -period 20.000 [get_ports {FPGA_CLK1_50}]
create_clock -name FPGA_CLK2_50 -period 20.000 [get_ports {FPGA_CLK2_50}]
create_clock -name FPGA_CLK3_50 -period 20.000 [get_ports {FPGA_CLK3_50}]

# PLL-generated clocks
derive_pll_clocks
derive_clock_uncertainty

# HDMI clock is inverted relative to the 49 MHz pixel clock
create_generated_clock -name hdmi_tx_clk \
    -source [get_pins -compatibility_mode {u_pll_49|*|clk[0]}] \
    -invert \
    [get_ports {HDMI_TX_CLK}]

# ADV7513 source-synchronous output constraints
set_output_delay -clock {hdmi_tx_clk} -max 2.0 \
    [get_ports {HDMI_TX_D* HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]

set_output_delay -clock {hdmi_tx_clk} -min -1.0 \
    [get_ports {HDMI_TX_D* HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]

# Slow/asynchronous controls
set_false_path -from [get_ports {KEY* SW*}] -to *
set_false_path -from * -to [get_ports {LED*}]

set_false_path -from [get_ports {HDMI_TX_INT}] -to *
set_false_path -from * -to [get_ports {HDMI_I2C_SCL}]
set_false_path -from * -to [get_ports {HDMI_I2C_SDA}]
set_false_path -from [get_ports {HDMI_I2C_SDA}] -to *