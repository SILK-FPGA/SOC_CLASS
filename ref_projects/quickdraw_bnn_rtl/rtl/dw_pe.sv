module dw_pe (
    input  logic        clk,
    input  logic        rst_n,
    
    // Nguồn dữ liệu từ khối window3x3
    input  logic        valid_in,
    input  logic [8:0]  window_in, // 9 pixel (đã dàn phẳng 1D)
    
    // Nguồn trọng số (Load từ file dw_weights.hex / ROM)
    input  logic [8:0]  weight_in, 
    
    // Đầu ra đưa sang khối Pointwise (PW)
    output logic        valid_out,
    output logic [3:0]  data_out   // Kết quả Popcount: Số nguyên từ 0 đến 9
);

    // ==========================================
    // TẦNG PIPELINE 1: PHÉP NHÂN NHỊ PHÂN (CỔNG AND)
    // ==========================================
    logic [8:0] and_result;
    logic       valid1;
    logic [3:0] data_out_t;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= '0;
            valid1 <= 1'b0;
        end else begin
            // Trượt cờ Valid
            valid1 <= valid_in;
            
            if (valid_in) begin
                // Phép nhân trong không gian {0, 1} chính là cổng AND.
                // Thực hiện 9 phép tính song song trong 1 chu kỳ.
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
            // Trượt cờ Valid ra ngõ ra
            valid_out <= valid1;
            
            if (valid1) begin
                // Đếm tổng số bit 1
                data_out <= data_out_t;
            end
        end
    end

endmodule