module sobel_pe (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic        ready_in, 
    
    input  logic [7:0]  p00, p01, p02,
    input  logic [7:0]  p10, p11, p12,
    input  logic [7:0]  p20, p21, p22,
    
    output logic        valid_out,
    output logic [7:0]  pixel_out
);
    logic signed [10:0] gx, gy;
    logic [10:0] abs_gx, abs_gy;
    logic [11:0] sum;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            pixel_out <= 8'd0;
            gx <= '0; gy <= '0;
        end else if (ready_in) begin 
            gx <= -$signed({3'd0, p00}) + $signed({3'd0, p02}) 
                  -($signed({3'd0, p10}) <<< 1) + ($signed({3'd0, p12}) <<< 1) 
                  -$signed({3'd0, p20}) + $signed({3'd0, p22});
                  
            gy <= -$signed({3'd0, p00}) - ($signed({3'd0, p01}) <<< 1) - $signed({3'd0, p02}) 
                  +$signed({3'd0, p20}) + ($signed({3'd0, p21}) <<< 1) + $signed({3'd0, p22});
            

            abs_gx = (gx[10]) ? -gx : gx;
            abs_gy = (gy[10]) ? -gy : gy;
            sum = abs_gx + abs_gy;
            

            pixel_out <= (sum > 12'd255) ? 8'd255 : sum[7:0];
            valid_out <= valid_in;
        end
    end
endmodule

module sobel_accelerator #(
    parameter PARALLEL_PIXELS = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic valid_in, 
    input  logic ready_in, 
    
    input  logic [PARALLEL_PIXELS*72-1:0] window_3x3_array_in,
    output logic valid_out,
    output logic [PARALLEL_PIXELS*8-1:0] pixels_out
);

    logic [PARALLEL_PIXELS-1:0] pe_valid_out;
    assign valid_out = pe_valid_out[0];
    
    genvar i;
    generate
        for (i = 0; i < PARALLEL_PIXELS; i++) begin : gen_sobel_pe
            wire [7:0] w_p00 = window_3x3_array_in[i*72 + 8*0 +: 8];
            wire [7:0] w_p01 = window_3x3_array_in[i*72 + 8*1 +: 8];
            wire [7:0] w_p02 = window_3x3_array_in[i*72 + 8*2 +: 8];
            wire [7:0] w_p10 = window_3x3_array_in[i*72 + 8*3 +: 8];
            wire [7:0] w_p11 = window_3x3_array_in[i*72 + 8*4 +: 8];
            wire [7:0] w_p12 = window_3x3_array_in[i*72 + 8*5 +: 8];
            wire [7:0] w_p20 = window_3x3_array_in[i*72 + 8*6 +: 8];
            wire [7:0] w_p21 = window_3x3_array_in[i*72 + 8*7 +: 8];
            wire [7:0] w_p22 = window_3x3_array_in[i*72 + 8*8 +: 8];
            
            sobel_pe u_pe (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (valid_in),
                .ready_in  (ready_in), 
                .p00(w_p00), .p01(w_p01), .p02(w_p02),
                .p10(w_p10), .p11(w_p11), .p12(w_p12),
                .p20(w_p20), .p21(w_p21), .p22(w_p22),
                .valid_out (pe_valid_out[i]),
                .pixel_out (pixels_out[i*8 +: 8])
            );
        end
    endgenerate

endmodule
