module hdmi_i2c_config (
	input  logic        clk_i,
	input  logic        rst_i,
	input  logic        ena_i,
	input  logic        i2c_done_i,
	output logic        i2c_start_o,
	output logic [23:0] i2c_data_o,
	output logic        mem_done_o
);
	//VGA
	localparam END = 30;
	
	logic [23:0] mem [0:30] = '{
		//	Video Config Data
		24'h72_98_03,  //Must be set to 0x03 for proper operation
		24'h72_01_00,  //Set 'N' value at 6144
		24'h72_02_18,  //Set 'N' value at 6144
		24'h72_03_00,  //Set 'N' value at 6144
		24'h72_14_70,  // Set Ch count in the channel status to 8.
		24'h72_15_20,  //Input 444 (RGB or YCrCb) with Separate Syncs, 48kHz fs
		24'h72_16_30,  //Output format 444, 24-bit input
		24'h72_18_46,  //Disable CSC
		24'h72_40_80,  //General control packet enable
		24'h72_41_10,  //Power down control
		24'h72_49_A8,  //Set dither mode - 12-to-10 bit
		24'h72_55_10,  //Set RGB in AVI infoframe
		24'h72_56_08,  //Set active format aspect
		24'h72_96_F6,  //Set interrup
		24'h72_73_07,  //Info frame Ch count to 8
		24'h72_76_1f,  //Set speaker allocation for 8 channels
		24'h72_98_03,  //Must be set to 0x03 for proper operation
		24'h72_99_02,  //Must be set to Default Value
		24'h72_9a_e0,  //Must be set to 0b1110000
		24'h72_9c_30,  //PLL filter R1 value
		24'h72_9d_61,  //Set clock divide
		24'h72_a2_a4,  //Must be set to 0xA4 for proper operation
		24'h72_a3_a4,  //Must be set to 0xA4 for proper operation
		24'h72_a5_04,  //Must be set to Default Value
		24'h72_ab_40,  //Must be set to Default Value
		24'h72_af_16,  //Select HDMI mode
		24'h72_ba_60,  //No clock delay
		24'h72_d1_ff,  //Must be set to Default Value
		24'h72_de_10,  //Must be set to Default for proper operation
		24'h72_e4_60,  //Must be set to Default Value
		24'h72_fa_7d   //Nbr of times to look for good phase
	};
	
	logic [4:0] addr, n_addr;
	assign i2c_data_o = mem[addr];
	
	localparam 	IDLE = 0,
					SEND = 1,
					STOP = 2;
					
	logic [1:0] state, n_state;
	
	logic i2c_start, n_i2c_start;
	assign i2c_start_o = i2c_start;
	logic mem_done, n_mem_done;
	assign mem_done_o = mem_done;

	always_comb begin
		n_addr      = addr;
		n_state     = state;
		n_i2c_start = 1'b0;
		n_mem_done  = mem_done;
		case (state) 
			IDLE: begin
				if (ena_i) begin
					n_state = SEND;
					n_i2c_start = 1'b1;
					n_addr = addr + 1'b1;
				end
			end
			
			SEND: begin
				if (i2c_done_i) begin
					n_i2c_start = 1'b1;
					n_addr = addr + 1'b1;
				end
				if (addr == END) begin
					n_state = STOP;
				end
			end
			
			STOP: begin
				if (i2c_done_i) begin
					n_mem_done = 1'b1;
				end
			end
			
			default: n_state = IDLE;
		endcase
	end
	
	always_ff @(posedge clk_i) begin
		if (!rst_i) begin 
			addr         <= 0;
			state        <= IDLE;
			i2c_start    <= 0;
			mem_done     <= 0;
		end else begin 
			addr         <= n_addr;
			state        <= n_state;
			i2c_start    <= n_i2c_start;
			mem_done     <= n_mem_done;
		end
	end
	
endmodule

