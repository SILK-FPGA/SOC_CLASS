module dw_pe (
    input  logic        clk,
    input  logic        rst_n,
    

    input  logic        valid_in,
    input  logic [8:0]  window_in, 

    input  logic [8:0]  weight_in, 
    
    //to pw
    output logic        valid_out,
    output logic [3:0]  data_out   // Kết quả popcount: Số nguyên từ 0 đến 9
);


    logic [8:0] and_result;
    logic       valid1;
    logic [3:0] data_out_t;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= '0;
            valid1 <= 1'b0;
        end else begin

            valid1 <= valid_in;
            
            if (valid_in) begin

                and_result <= window_in & weight_in; 
            end
        end
    end

    popcount # (9)
    popcount (
    .data_in(and_result),
    .count_out(data_out_t)
    );
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= '0;
            valid_out <= 1'b0;
        end else begin

            valid_out <= valid1;
            
            if (valid1) begin

                data_out <= data_out_t;
            end
        end
    end

endmodule