module parallel_line_buffer #(
    parameter IMG_WIDTH      = 640,
    parameter PIXELS_PER_CLK = 32 // 256-bit = 32 pixel 8-bit
)(
    input  logic clk,
    input  logic rst_n,
    
    input  logic valid_in,
    input  logic ready_in,
    input  logic [PIXELS_PER_CLK*8-1:0] din,
    
    output logic valid_out,
    output logic [PIXELS_PER_CLK*72-1:0] window_array_out 
);

    localparam WORDS_PER_LINE = IMG_WIDTH / PIXELS_PER_CLK;
    
    
    logic [PIXELS_PER_CLK*8-1:0] row2_current, row2_prev;
    logic [PIXELS_PER_CLK*8-1:0] row1_current, row1_prev;
    logic [PIXELS_PER_CLK*8-1:0] row0_current, row0_prev;
    
    
    logic [7:0] row2_left_halo, row1_left_halo, row0_left_halo;

    
    logic [PIXELS_PER_CLK*8-1:0] fifo_line1 [0:WORDS_PER_LINE-1];
    logic [PIXELS_PER_CLK*8-1:0] fifo_line2 [0:WORDS_PER_LINE-1];
    logic [$clog2(WORDS_PER_LINE)-1:0] wr_ptr, rd_ptr;
    
    logic [1:0] line_count;
    logic valid_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= 1; 
            line_count <= '0;
            valid_q <= 1'b0;
            
            row2_left_halo <= '0;
            row1_left_halo <= '0;
            row0_left_halo <= '0;
            
            row2_current <= '0; row2_prev <= '0;
            row1_current <= '0; row1_prev <= '0;
            row0_current <= '0; row0_prev <= '0;
        end else if (ready_in) begin  
            if (valid_in) begin
                
                row2_prev <= row2_current;
                row2_current <= din;
                row2_left_halo <= row2_prev[PIXELS_PER_CLK*8-1 -: 8]; 
                
                row1_prev <= row1_current;
                row1_current <= fifo_line1[rd_ptr];
                row1_left_halo <= row1_prev[PIXELS_PER_CLK*8-1 -: 8];
                
                row0_prev <= row0_current;
                row0_current <= fifo_line2[rd_ptr];
                row0_left_halo <= row0_prev[PIXELS_PER_CLK*8-1 -: 8];
                
                fifo_line1[wr_ptr] <= row2_current;
                fifo_line2[wr_ptr] <= row1_current;
                
                if (wr_ptr == WORDS_PER_LINE - 1) begin
                    wr_ptr <= '0;
                    rd_ptr <= 1;
                    if (line_count < 2) line_count <= line_count + 1'b1;
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= (rd_ptr == WORDS_PER_LINE - 1) ? '0 : rd_ptr + 1'b1;
                end
                
                valid_q <= 1'b1;
            end else begin
                valid_q <= 1'b0;
            end
        end 
    end 
    
    assign valid_out = valid_q && (line_count == 2);

   
    wire [PIXELS_PER_CLK*8+15:0] window_src_row2 = {row2_current[7:0], row2_prev, row2_left_halo};
    wire [PIXELS_PER_CLK*8+15:0] window_src_row1 = {row1_current[7:0], row1_prev, row1_left_halo};
    wire [PIXELS_PER_CLK*8+15:0] window_src_row0 = {row0_current[7:0], row0_prev, row0_left_halo};

    genvar i;
    generate
        for (i = 0; i < PIXELS_PER_CLK; i++) begin : gen_windows
            localparam BASE = i * 8; 
            
            wire [7:0] p00 = window_src_row0[BASE      +: 8];
            wire [7:0] p01 = window_src_row0[BASE + 8  +: 8];
            wire [7:0] p02 = window_src_row0[BASE + 16 +: 8];
            
            wire [7:0] p10 = window_src_row1[BASE      +: 8];
            wire [7:0] p11 = window_src_row1[BASE + 8  +: 8];
            wire [7:0] p12 = window_src_row1[BASE + 16 +: 8];
            
            wire [7:0] p20 = window_src_row2[BASE      +: 8];
            wire [7:0] p21 = window_src_row2[BASE + 8  +: 8];
            wire [7:0] p22 = window_src_row2[BASE + 16 +: 8];
            
            assign window_array_out[i*72 +: 72] = {p22, p21, p20, p12, p11, p10, p02, p01, p00};
        end
    endgenerate

endmodule
