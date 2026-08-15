module i2ctx (
	input  logic clk_i,
	input  logic rst_i,
	input  logic start_i,
	input  logic [23:0] datatx_i,
	input  logic datarx_i,
	output logic sda_sel_o,
	output logic txdone_o,
	output logic sda_o,
	output logic scl_o
);

	logic sda, scl;
	logic sda_sel;
	logic txdone;
	logic true_ack;
	logic rw_bit;
	logic [2:0] bcount, n_bcount; //bit
	logic [1:0] n_bsel, bsel;     //bit
	logic [1:0] scount, n_scount; //state 
	logic [12:0] count, n_count;   
	logic [3:0] state, n_state;
	logic [3:0] bstate, n_bstate;
	logic [7:0] breg, n_breg, b;
	localparam  ack = 0;

	localparam  IDLE          = 0,
					START         = 1,
					TX_BYTE       = 2,
					ACK           = 3,
					REPEAT_START  = 4,
					RX_DATA       = 5,
					NACK          = 6,
					STOP          = 7,
					HOLD_ACK      = 8;
				
	always_comb begin
		case (bsel)
			2'd0: b = datatx_i[23:16];
			2'd1: b = datatx_i[15:8];
			2'd2: b = datatx_i[7:0];
			default: b = 0;
		endcase
	end
	
	assign true_ack = (datarx_i == ack) ? 1 : 0;
	
	always_comb begin 
			sda      = sda_o;
			scl      = scl_o;
			n_state  = state;
			n_bstate = bstate;
			sda_sel  = sda_sel_o;
			txdone   = 0;
			n_count  = count;
			n_bcount = bcount;
			n_breg   = breg;
			n_bsel   = bsel;
			n_scount = scount;
		case (state) 
			IDLE: begin 
				sda = 1;
				scl = 1;
				n_state = (start_i) ? START: IDLE;
				n_count = 0;
				n_bcount = 0;
				n_scount = 0;
				n_bsel = 0;
				sda_sel = 0; 
			end
			
			START: begin 
				sda = 0;
				if (count == 1999) begin 
					n_state = TX_BYTE;
					n_count = 0;
				end else begin 
					n_count = count + 1;
					n_state = START;
					if (count == 999) begin 
						scl = 0;
					end 
				end
			end
			
			TX_BYTE: begin 
				n_breg = b;
				if ((count == 1999)&&(bcount == 7)) begin
					n_state = ACK;
					n_bcount = 0;
					sda_sel = 1;
					sda = 1;
					scl = 0;
					n_count = 0;
					n_scount = scount + 1;
				end else begin 
					n_state = TX_BYTE;
					sda_sel = 0;
					if (count == 1) begin //breg update 
						scl = 0;
						sda = breg [7-bcount];
					end
					if (count == 999) begin 
						scl = 1;
					end
					if (count == 1999) begin 
						n_count = 0;
						n_bcount = bcount + 1;
					end else begin 
						n_count = count + 1;
					end
				end
			end
			
			ACK: begin
				if (count == 1999) begin 
					n_count = 0;
					sda_sel = 0;
					scl = 0;
					n_bsel = bsel + 1;
					n_state = HOLD_ACK;
				end else begin 
					n_count = count + 1;
					if (count == 999) begin 
						scl = 1;
						if (n_scount == 3)
							n_bstate = STOP;
						else
							n_bstate = (true_ack) ? TX_BYTE : REPEAT_START; //check ack
					end
				end
			end
			
			HOLD_ACK: begin 	
				if (count == 999) begin
					n_state = bstate;
					n_count = 0;
				end else begin
					n_count = count + 1;
				end
			end
			
			STOP: begin 
				if (count == 5000) begin 
					sda = 1;
					scl = 1;
					n_state = IDLE;
					n_count = 0;
					txdone = 1;
				end else begin 
					n_count = count + 1;
					if (count == 0)
						sda = 0;
					if (count == 999)
						scl = 1;
					if (count == 1999) begin
						sda = 1;
					end
				end	
			end
			
			REPEAT_START: begin 
				if (count == 1919) begin
					n_state = START;
					n_count = 0;
					n_bcount = 0;
					n_scount = 0;
					n_bsel = 0;
					sda_sel = 0;
				end else begin 
					n_count = count + 1;
					if (count == 0)
						sda = 0;
					if (count == 239)
						scl = 1;
					if (count == 479)
						sda = 1;
					if (count == 1439) 
						sda = 0;
					if (count == 1679) 
						scl = 0;
				end
			end

			
			default: n_state = IDLE;
		endcase
	end
				
	always_ff @(posedge clk_i) begin
		if (!rst_i) begin 
			state     <= IDLE;
			bstate    <= 0;
			sda_o     <= 1;
			scl_o     <= 1;
			sda_sel_o <= 0;
			txdone_o  <= 0;
			count     <= 0; 
			bcount    <= 0;
			breg      <= 0;
			bsel      <= 0;
			scount    <= 0;
		end else begin 
			state     <= n_state;
			bstate    <= n_bstate;
			sda_o     <= sda;
			scl_o     <= scl;
			sda_sel_o <= sda_sel;
			txdone_o  <= txdone;
			count     <= n_count;
			bcount    <= n_bcount;
			breg      <= n_breg;
			bsel      <= n_bsel;
			scount    <= n_scount;
		end
	end

	
endmodule
