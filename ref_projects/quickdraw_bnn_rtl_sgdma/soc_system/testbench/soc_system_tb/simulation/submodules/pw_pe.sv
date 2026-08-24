module pw_pe (
    input  logic        clk,
    input  logic        rst_n,
    
    
    input  logic        valid_in,
    input  logic [3:0]  dw_out_0,  // Số nguyên (0-9) từ kênh 0
    input  logic [3:0]  dw_out_1,  // Số nguyên (0-9) từ kênh 1
    input  logic [3:0]  dw_out_2,  // Số nguyên (0-9) từ kênh 2
    
    input  logic [2:0]  weight_in, 
    input  logic [16:0] thresh_in, 
    

    output logic        valid_out,
    output logic        data_out   
);


    logic [3:0] sum_pw2, sum_pw1, sum_pw0;

    assign sum_pw2 = weight_in[2] ? dw_out_2 : 4'd0;
    assign sum_pw1 = weight_in[1] ? dw_out_1 : 4'd0;
    assign sum_pw0 = weight_in[0] ? dw_out_0 : 4'd0;


    logic [4:0]  sum_pw_r;
    logic        valid1;
    logic [16:0] thresh1; 

    always_ff @(posedge clk or negedge rst_n) begin : sum_pw
        if (!rst_n) begin
            thresh1  <= '0;
            valid1   <= 1'b0;
            sum_pw_r <= '0;
        end else begin

            valid1 <= valid_in; 
            
            if (valid_in) begin
                thresh1  <= thresh_in;
                sum_pw_r <= sum_pw0 + sum_pw1 + sum_pw2;
            end
        end
    end


    logic polarity; 
    logic signed [15:0] thresh_value;
    logic signed [6:0]  sum_signed; 
    logic data_out_t;

    assign polarity     = thresh1[16];
    assign thresh_value = thresh1[15:0];
    assign sum_signed   = {2'b00, sum_pw_r}; 

    assign data_out_t = (polarity) ? 
                        ((sum_signed >= thresh_value) ? 1'b1 : 1'b0) : 
                        ((sum_signed <= thresh_value) ? 1'b1 : 1'b0);

    always_ff @(posedge clk or negedge rst_n) begin : outputreg
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out  <= 1'b0;
        end else begin

            valid_out <= valid1; 
            
            if (valid1) begin
                data_out <= data_out_t;
            end
        end
    end

endmodule