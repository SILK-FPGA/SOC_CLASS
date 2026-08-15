module fc1_folded_neuron (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic        pw_valid,
    input  logic [7:0]  pixel_cnt,  // Quét 0 -> 168 (169 pixels)
    input  logic [17:0] pw_data,    // 18 kênh từ PW
    
    input  logic [17:0] weight_fm,  // 18-bit trọng số
    input  logic [16:0] thresh_in,  
    
    output logic        valid_out,
    output logic        data_out
);

    // 1. MAC: AND + Popcount 18-bit
    logic [17:0] and_fm;
    logic [4:0]  pop_fm;
    assign and_fm = pw_data & weight_fm;
    popcount #(18) pc_fm (.data_in(and_fm), .count_out(pop_fm));

    // Thanh ghi cộng dồn
    logic [11:0] acc;
    logic        compute_done;
    logic [16:0] thresh_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= '0;
            compute_done <= 1'b0;
            thresh_reg <= '0;
        end else begin
            compute_done <= 1'b0;
            if (pw_valid) begin
                if (pixel_cnt == 8'd0) begin
                    acc <= pop_fm; // Ghi đè ở pixel 0
                end else if (pixel_cnt == 8'd168) begin
                    acc <= acc + pop_fm; // Pixel cuối (168)
                    compute_done <= 1'b1;
                    thresh_reg <= thresh_in;
                end else begin
                    acc <= acc + pop_fm; // Tích lũy
                end
            end
        end
    end

    // 2. SO SÁNH NGƯỠNG
    logic polarity;
    logic signed [15:0] thresh_value;
    logic signed [12:0] sum_signed;
    logic data_out_t;

    assign polarity     = thresh_reg[16];
    assign thresh_value = thresh_reg[15:0];
    assign sum_signed   = {1'b0, acc}; // Ép sang số có dấu dương

    assign data_out_t = (polarity) ? 
                        ((sum_signed >= thresh_value) ? 1'b1 : 1'b0) : 
                        ((sum_signed <= thresh_value) ? 1'b1 : 1'b0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out  <= 1'b0;
        end else begin
            valid_out <= compute_done;
            if (compute_done) data_out <= data_out_t;
        end
    end
endmodule