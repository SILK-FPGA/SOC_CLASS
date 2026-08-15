module read_avalon_sdr (
	// clk and reset are always required.
	input   logic         clk,
	input   logic         reset,
	// Bidirectional ports i.e. read and write.
	output  logic         avm_m0_read,
	output  logic         avm_m0_write,
	output  logic [255:0] avm_m0_writedata,
	output  logic [31:0]  avm_m0_address,
	input   logic [255:0] avm_m0_readdata,
	input   logic         avm_m0_readdatavalid,
	output  logic [31:0]  avm_m0_byteenable,
	input   logic         avm_m0_waitrequest,
	output  logic [10:0]  avm_m0_burstcount,
	// External.
	input   logic         read_start_i,
	output  logic         read_reset_o,
	output  logic [255:0] read_data_o,
	output  logic         read_enable_o,
	output  logic         read_done_o
);

	localparam INIT                  = 3'd0;
	localparam READ_START            = 3'd1;
	localparam READ_END              = 3'd2;
	localparam READ_STOP             = 3'd3;
	localparam READ_DELAY            = 3'd4;
	

	localparam ADDRESS = 32'h3000_0000;
	
	localparam MAX = 160*120/32/8;

	logic [2:0] state, n_state;
	logic [25:0] count, n_count;
	logic [2:0] brcount, n_brcount; //brust_count
	
	//input 
	logic read_start_reg;
	logic read_start_rise;
	assign read_start_rise = !read_start_reg & read_start_i;

	//output
	logic read_reset, n_read_reset;
	assign read_reset_o = read_reset;
	logic [255:0] read_data, n_read_data;
	assign read_data_o = read_data;
	logic read_enable, n_read_enable;
	assign read_enable_o = read_enable;
	logic read_done, n_read_done;
	assign read_done_o = read_done;
	
	//avalon_read
	logic read, n_read;
	assign avm_m0_read = read;
	logic [31:0] address, n_address;
	assign avm_m0_address = address;
	
	always_comb begin
			n_state            = state;
			n_count            = count;
			n_brcount          = brcount;
			n_read             = read;
			n_address          = address;
			n_read_reset       = read_reset;
			n_read_data        = read_data;
			n_read_enable      = 1'b0;
			n_read_done        = read_done;
			avm_m0_write       = 1'b0;
			avm_m0_writedata   = '0;           
//			avm_m0_address     = 32'h0;
//			avm_m0_read        = 1'b0;
			avm_m0_byteenable  = 32'hFFFF_FFFF;
			avm_m0_burstcount  = 11'd4;
			
	case (state)
		INIT: begin
			if (read_start_rise) begin
				n_state = READ_DELAY;
				n_address = ADDRESS;
				n_count = '0;
				n_brcount = '0;
				n_read_reset = 1'b1;
				n_read_done = '0;
			end
		end
		
		READ_DELAY: begin
			if (count == 67000000) begin
				n_state = READ_START;
				n_read = 1'b1;
				n_count = '0;
				n_read_reset = '0;
			end else begin
				n_count = count + 1;
			end
		end
		
		READ_START: begin
			if (!avm_m0_waitrequest) begin
				n_state = READ_END;
				n_read = '0;
			end
		end
		
		READ_END: begin
			if (avm_m0_readdatavalid) begin	
				if (brcount == 3'd3) begin
					n_state = READ_STOP;
					n_brcount = '0;
				end else begin
					n_brcount = brcount + 1'b1;
				end
				n_read_data = avm_m0_readdata;
				n_read_enable = 1'b1;
			end
		end
	
		READ_STOP: begin
			if (count == '0) begin
				n_state = INIT;
				n_read_done = 1'b1;
			end else begin
				n_state = READ_START;
				n_read = 1'b1;
				n_address = address + 32'd256;
				n_count = count + 1'b1;
			end
		end
	
		default: n_state = INIT;
		endcase
	end
			
	always_ff @(posedge clk) begin
		if (reset) begin	
			state          <= INIT;
			read           <= '0;
			address        <= '0;
			count          <= '0;
			brcount        <= '0;
			read_reset     <= '0;
			read_data      <= '0;
			read_enable    <= '0;
			read_done      <= '0;
			read_start_reg <= '0;
		end else begin
			state          <= n_state;
			read           <= n_read;
			address        <= n_address;
			count          <= n_count;
			brcount        <= n_brcount;
			read_reset     <= n_read_reset;
			read_data      <= n_read_data;
			read_enable    <= n_read_enable;
			read_done      <= n_read_done;
			read_start_reg <= read_start_i;
		end
	end

endmodule


