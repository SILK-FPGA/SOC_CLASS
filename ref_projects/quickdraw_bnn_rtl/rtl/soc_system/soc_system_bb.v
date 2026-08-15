
module soc_system (
	ai_result_i_export,
	clk_clk,
	ext_connect_o_export,
	hps_0_h2f_reset_reset_n,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	read_data_o_export,
	read_done_o_export,
	read_enable_o_export,
	read_reset_o_export,
	read_start_i_export,
	reset_reset_n);	

	input	[31:0]	ai_result_i_export;
	input		clk_clk;
	output		ext_connect_o_export;
	output		hps_0_h2f_reset_reset_n;
	output	[14:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[31:0]	memory_mem_dq;
	inout	[3:0]	memory_mem_dqs;
	inout	[3:0]	memory_mem_dqs_n;
	output		memory_mem_odt;
	output	[3:0]	memory_mem_dm;
	input		memory_oct_rzqin;
	output	[255:0]	read_data_o_export;
	output		read_done_o_export;
	output		read_enable_o_export;
	output		read_reset_o_export;
	input		read_start_i_export;
	input		reset_reset_n;
endmodule
