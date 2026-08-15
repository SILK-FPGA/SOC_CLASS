module mcp_pe (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic        valid_in,
    input  logic [15:0] window_in, // Cửa sổ 16 bit
    input  logic [15:0] weight_in, // Trọng số 16 bit
    input  logic [16:0] thresh_in, // Ngưỡng 17 bit
    
    output logic        valid_out,
    output logic        data_out   // Kết quả 1 bit
);
    // TẦNG 1: CHỐT PHÉP AND
    logic [15:0] and_res;
    logic        valid1;
    logic [16:0] thresh1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_res <= '0;
            valid1  <= 1'b0;
            thresh1 <= '0;
        end else begin
            valid1 <= valid_in; 
            if (valid_in) begin
                and_res <= window_in & weight_in;
                thresh1 <= thresh_in;
            end
        end
    end

    // GỌI MODULE POPCOUNT BÊN NGOÀI
    logic [4:0] pop_cnt; // Tối đa 16 bit 1
    popcount #(16) u_pop (.data_in(and_res), .count_out(pop_cnt));

    // TẦNG 2: SO SÁNH NGƯỠNG
    logic polarity;
    logic signed [15:0] thresh_val;
    logic signed [5:0]  sum_signed; // Ép số có dấu
    logic data_out_t;

    assign polarity   = thresh1[16];
    assign thresh_val = thresh1[15:0];
    assign sum_signed = {1'b0, pop_cnt}; 

    assign data_out_t = polarity ? (sum_signed >= thresh_val) : (sum_signed <= thresh_val);

    always_ff @(posedge clk or negedge rst_n) begin
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