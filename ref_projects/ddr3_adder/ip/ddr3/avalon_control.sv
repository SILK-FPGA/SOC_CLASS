module avalon_control(
    /* verilator lint_off UNUSED */
    input logic clk,
    input logic reset,
    input logic [31:0] avs_s0_writedata,
    /* verilator lint_on UNUSED */
    input logic avs_s0_write, //from cpu 
    output logic do_read,
    output logic [10:0] burst_length, //11 bit
    output logic [19:0] init_addr //20 bit

  );

  logic [31:0] ctrl_reg;

  assign ctrl_reg = (avs_s0_write) ? avs_s0_writedata : 0; // description register
  assign do_read = ctrl_reg[0]; // read flag
  assign burst_length = ctrl_reg[11:1]; //2
  assign init_addr = ctrl_reg[31:12]; // start address
  
endmodule
