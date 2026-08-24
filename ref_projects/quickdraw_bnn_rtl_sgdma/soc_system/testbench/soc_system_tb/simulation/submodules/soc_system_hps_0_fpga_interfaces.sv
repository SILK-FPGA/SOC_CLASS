// (C) 2001-2020 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ns / 1 ns

import verbosity_pkg::*;
import avalon_mm_pkg::*;
import mgc_axi_pkg::*;

module soc_system_hps_0_fpga_interfaces
(
   output wire [  0:  0] h2f_rst_n,
   input  wire [  0:  0] h2f_lw_axi_clk,
   output wire [ 11:  0] h2f_lw_AWID,
   output wire [ 20:  0] h2f_lw_AWADDR,
   output wire [  3:  0] h2f_lw_AWLEN,
   output wire [  2:  0] h2f_lw_AWSIZE,
   output wire [  1:  0] h2f_lw_AWBURST,
   output wire [  1:  0] h2f_lw_AWLOCK,
   output wire [  3:  0] h2f_lw_AWCACHE,
   output wire [  2:  0] h2f_lw_AWPROT,
   output wire [  0:  0] h2f_lw_AWVALID,
   input  wire [  0:  0] h2f_lw_AWREADY,
   output wire [ 11:  0] h2f_lw_WID,
   output wire [ 31:  0] h2f_lw_WDATA,
   output wire [  3:  0] h2f_lw_WSTRB,
   output wire [  0:  0] h2f_lw_WLAST,
   output wire [  0:  0] h2f_lw_WVALID,
   input  wire [  0:  0] h2f_lw_WREADY,
   input  wire [ 11:  0] h2f_lw_BID,
   input  wire [  1:  0] h2f_lw_BRESP,
   input  wire [  0:  0] h2f_lw_BVALID,
   output wire [  0:  0] h2f_lw_BREADY,
   output wire [ 11:  0] h2f_lw_ARID,
   output wire [ 20:  0] h2f_lw_ARADDR,
   output wire [  3:  0] h2f_lw_ARLEN,
   output wire [  2:  0] h2f_lw_ARSIZE,
   output wire [  1:  0] h2f_lw_ARBURST,
   output wire [  1:  0] h2f_lw_ARLOCK,
   output wire [  3:  0] h2f_lw_ARCACHE,
   output wire [  2:  0] h2f_lw_ARPROT,
   output wire [  0:  0] h2f_lw_ARVALID,
   input  wire [  0:  0] h2f_lw_ARREADY,
   input  wire [ 11:  0] h2f_lw_RID,
   input  wire [ 31:  0] h2f_lw_RDATA,
   input  wire [  1:  0] h2f_lw_RRESP,
   input  wire [  0:  0] h2f_lw_RLAST,
   input  wire [  0:  0] h2f_lw_RVALID,
   output wire [  0:  0] h2f_lw_RREADY,
   input  wire [ 31:  0] f2h_sdram0_ARADDR,
   input  wire [  3:  0] f2h_sdram0_ARLEN,
   input  wire [  7:  0] f2h_sdram0_ARID,
   input  wire [  2:  0] f2h_sdram0_ARSIZE,
   input  wire [  1:  0] f2h_sdram0_ARBURST,
   input  wire [  1:  0] f2h_sdram0_ARLOCK,
   input  wire [  2:  0] f2h_sdram0_ARPROT,
   input  wire [  0:  0] f2h_sdram0_ARVALID,
   input  wire [  3:  0] f2h_sdram0_ARCACHE,
   input  wire [ 31:  0] f2h_sdram0_AWADDR,
   input  wire [  3:  0] f2h_sdram0_AWLEN,
   input  wire [  7:  0] f2h_sdram0_AWID,
   input  wire [  2:  0] f2h_sdram0_AWSIZE,
   input  wire [  1:  0] f2h_sdram0_AWBURST,
   input  wire [  1:  0] f2h_sdram0_AWLOCK,
   input  wire [  2:  0] f2h_sdram0_AWPROT,
   input  wire [  0:  0] f2h_sdram0_AWVALID,
   input  wire [  3:  0] f2h_sdram0_AWCACHE,
   output wire [  1:  0] f2h_sdram0_BRESP,
   output wire [  7:  0] f2h_sdram0_BID,
   output wire [  0:  0] f2h_sdram0_BVALID,
   input  wire [  0:  0] f2h_sdram0_BREADY,
   output wire [  0:  0] f2h_sdram0_ARREADY,
   output wire [  0:  0] f2h_sdram0_AWREADY,
   input  wire [  0:  0] f2h_sdram0_RREADY,
   output wire [ 63:  0] f2h_sdram0_RDATA,
   output wire [  1:  0] f2h_sdram0_RRESP,
   output wire [  0:  0] f2h_sdram0_RLAST,
   output wire [  7:  0] f2h_sdram0_RID,
   output wire [  0:  0] f2h_sdram0_RVALID,
   input  wire [  0:  0] f2h_sdram0_WLAST,
   input  wire [  0:  0] f2h_sdram0_WVALID,
   input  wire [ 63:  0] f2h_sdram0_WDATA,
   input  wire [  7:  0] f2h_sdram0_WSTRB,
   output wire [  0:  0] f2h_sdram0_WREADY,
   input  wire [  7:  0] f2h_sdram0_WID,
   input  wire [  0:  0] f2h_sdram0_clk,
   input  wire [ 31:  0] f2h_irq_p0,
   input  wire [ 31:  0] f2h_irq_p1
);




   altera_avalon_reset_source #(
      .ASSERT_HIGH_RESET(0),
      .INITIAL_RESET_CYCLES(1)
   ) h2f_reset_inst (
      .reset(h2f_rst_n),
      .clk('0)
   );

   altera_avalon_interrupt_sink #(
      .ASSERT_HIGH_IRQ(1),
      .AV_IRQ_W(32),
      .ASYNCHRONOUS_INTERRUPT(1)
   ) f2h_irq1_inst (
      .irq(f2h_irq_p1),
      .reset('0),
      .clk('0)
   );

   altera_avalon_interrupt_sink #(
      .ASSERT_HIGH_IRQ(1),
      .AV_IRQ_W(32),
      .ASYNCHRONOUS_INTERRUPT(1)
   ) f2h_irq0_inst (
      .irq(f2h_irq_p0),
      .reset('0),
      .clk('0)
   );

   mgc_axi_master #(
      .AXI_ID_WIDTH(12),
      .AXI_ADDRESS_WIDTH(21),
      .AXI_WDATA_WIDTH(32),
      .AXI_RDATA_WIDTH(32),
      .index(2)
   ) h2f_lw_axi_master_inst (
      .ARSIZE(h2f_lw_ARSIZE),
      .AWUSER(),
      .WVALID(h2f_lw_WVALID),
      .RLAST(h2f_lw_RLAST),
      .ACLK(h2f_lw_axi_clk),
      .RRESP(h2f_lw_RRESP),
      .ARREADY(h2f_lw_ARREADY),
      .ARPROT(h2f_lw_ARPROT),
      .ARADDR(h2f_lw_ARADDR),
      .BVALID(h2f_lw_BVALID),
      .ARID(h2f_lw_ARID),
      .BID(h2f_lw_BID),
      .ARBURST(h2f_lw_ARBURST),
      .ARCACHE(h2f_lw_ARCACHE),
      .AWVALID(h2f_lw_AWVALID),
      .WDATA(h2f_lw_WDATA),
      .ARUSER(),
      .RID(h2f_lw_RID),
      .RVALID(h2f_lw_RVALID),
      .WREADY(h2f_lw_WREADY),
      .AWLOCK(h2f_lw_AWLOCK),
      .BRESP(h2f_lw_BRESP),
      .ARLEN(h2f_lw_ARLEN),
      .AWSIZE(h2f_lw_AWSIZE),
      .AWLEN(h2f_lw_AWLEN),
      .BREADY(h2f_lw_BREADY),
      .AWID(h2f_lw_AWID),
      .RDATA(h2f_lw_RDATA),
      .AWREADY(h2f_lw_AWREADY),
      .ARVALID(h2f_lw_ARVALID),
      .WLAST(h2f_lw_WLAST),
      .ARESETn(h2f_rst_n),
      .AWPROT(h2f_lw_AWPROT),
      .WID(h2f_lw_WID),
      .AWADDR(h2f_lw_AWADDR),
      .AWCACHE(h2f_lw_AWCACHE),
      .ARLOCK(h2f_lw_ARLOCK),
      .AWBURST(h2f_lw_AWBURST),
      .RREADY(h2f_lw_RREADY),
      .WSTRB(h2f_lw_WSTRB)
   );

// (C) 2001-2020 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.




wire [11 - 1 : 0] intermediate;
assign intermediate[2:2] = intermediate[8:8];
assign intermediate[10:10] = intermediate[8:8];
assign intermediate[6:6] = intermediate[4:4];
assign intermediate[7:7] = intermediate[8:8];
assign intermediate[5:5] = intermediate[3:3];
assign intermediate[9:9] = intermediate[8:8];
assign intermediate[1:1] = intermediate[0:0];
assign intermediate[0:0] = f2h_sdram0_RREADY[0:0];
assign intermediate[3:3] = f2h_sdram0_WLAST[0:0];
assign intermediate[4:4] = f2h_sdram0_WVALID[0:0];
assign intermediate[8:8] = f2h_sdram0_clk[0:0];

cyclonev_hps_interface_fpga2sdram f2sdram(
 .cmd_data_1({
    f2h_sdram0_AWPROT[1:0] // 59:58
   ,f2h_sdram0_AWLOCK[1:0] // 57:56
   ,f2h_sdram0_AWBURST[1:0] // 55:54
   ,f2h_sdram0_AWSIZE[2:0] // 53:51
   ,f2h_sdram0_AWID[7:0] // 50:43
   ,4'b0000 // 42:39
   ,f2h_sdram0_AWLEN[3:0] // 38:35
   ,f2h_sdram0_AWADDR[31:0] // 34:3
   ,1'b0 // 2:2
   ,1'b1 // 1:1
   ,1'b0 // 0:0
  })
,.wr_valid_0({
    intermediate[6:6] // 0:0
  })
,.cmd_data_0({
    f2h_sdram0_ARPROT[1:0] // 59:58
   ,f2h_sdram0_ARLOCK[1:0] // 57:56
   ,f2h_sdram0_ARBURST[1:0] // 55:54
   ,f2h_sdram0_ARSIZE[2:0] // 53:51
   ,f2h_sdram0_ARID[7:0] // 50:43
   ,4'b0000 // 42:39
   ,f2h_sdram0_ARLEN[3:0] // 38:35
   ,f2h_sdram0_ARADDR[31:0] // 34:3
   ,1'b0 // 2:2
   ,1'b0 // 1:1
   ,1'b1 // 0:0
  })
,.cfg_port_width({
    12'b000000000101 // 11:0
  })
,.rd_valid_0({
    f2h_sdram0_RVALID[0:0] // 0:0
  })
,.wr_clk_0({
    intermediate[7:7] // 0:0
  })
,.cfg_cport_type({
    12'b000000000110 // 11:0
  })
,.wr_data_0({
    17'b00000000000000000 // 89:73
   ,intermediate[5:5] // 72:72
   ,f2h_sdram0_WSTRB[7:0] // 71:64
   ,f2h_sdram0_WDATA[63:0] // 63:0
  })
,.cfg_rfifo_cport_map({
    16'b0000000000000000 // 15:0
  })
,.cfg_cport_wfifo_map({
    18'b000000000000000000 // 17:0
  })
,.cmd_port_clk_1({
    intermediate[10:10] // 0:0
  })
,.cmd_port_clk_0({
    intermediate[9:9] // 0:0
  })
,.cfg_cport_rfifo_map({
    18'b000000000000000000 // 17:0
  })
,.wrack_data_1({
    f2h_sdram0_BID[7:0] // 9:2
   ,f2h_sdram0_BRESP[1:0] // 1:0
  })
,.rd_ready_0({
    intermediate[1:1] // 0:0
  })
,.cmd_ready_1({
    f2h_sdram0_AWREADY[0:0] // 0:0
  })
,.rd_clk_0({
    intermediate[2:2] // 0:0
  })
,.cmd_ready_0({
    f2h_sdram0_ARREADY[0:0] // 0:0
  })
,.cfg_wfifo_cport_map({
    16'b0000000000000001 // 15:0
  })
,.wrack_ready_1({
    f2h_sdram0_BREADY[0:0] // 0:0
  })
,.cmd_valid_1({
    f2h_sdram0_AWVALID[0:0] // 0:0
  })
,.cmd_valid_0({
    f2h_sdram0_ARVALID[0:0] // 0:0
  })
,.wrack_valid_1({
    f2h_sdram0_BVALID[0:0] // 0:0
  })
,.wr_ready_0({
    f2h_sdram0_WREADY[0:0] // 0:0
  })
,.rd_data_0({
    f2h_sdram0_RID[7:0] // 74:67
   ,f2h_sdram0_RLAST[0:0] // 66:66
   ,f2h_sdram0_RRESP[1:0] // 65:64
   ,f2h_sdram0_RDATA[63:0] // 63:0
  })
,.cfg_axi_mm_select({
    6'b000011 // 5:0
  })
);




endmodule 

