module fc1_top (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         pw_valid,
    input  logic [17:0]  pw_data,    
    input  logic [3:0]   rr_data,    
    output logic         fc1_valid,
    output logic [31:0]  fc1_data_out
);

    // IMPORT PACKAGE TRỌNG SỐ VÀO ĐÂY
    import fc1_constants::*;

    // 1. THANH GHI DỊCH VÀ BỘ ĐẾM (Giữ nguyên)
    logic [3041:0] shift_reg;
    logic [7:0]    pixel_cnt;        
    logic          trigger_fc1; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg   <= '0;
            pixel_cnt   <= '0;
            trigger_fc1 <= 1'b0;
        end else begin
            trigger_fc1 <= 1'b0; 
            if (pw_valid) begin
                shift_reg <= {pw_data, shift_reg[3041:18]};
                if (pixel_cnt == 8'd168) begin
                    trigger_fc1 <= 1'b1;
                    pixel_cnt   <= '0; 
                end else begin
                    pixel_cnt   <= pixel_cnt + 1'b1;
                end
            end
        end
    end

    // 2. GHÉP MẢNG (Giữ nguyên)
    logic [3045:0] fc1_input_vector;
    assign fc1_input_vector = {rr_data, shift_reg}; 

    // 3. XÓA BỎ HOÀN TOÀN KHAI BÁO MẢNG VÀ INITIAL $READMEMH CŨ
    // (Ta sẽ dùng trực tiếp FC1_WEIGHTS và FC1_THRESH từ Package)

    // 4. NHÂN BẢN 32 NƠ-RON
    logic [31:0] valid_out_arr; 
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : gen_fc1_neurons
            fc1_neuron u_neuron (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (trigger_fc1),
                .data_in   (fc1_input_vector),
                // GỌI TRỰC TIẾP HẰNG SỐ TỪ PACKAGE
                .weight_in (FC1_WEIGHTS[i]),
                .thresh_in (FC1_THRESH[i]),
                .valid_out (valid_out_arr[i]),          
                .data_out  (fc1_data_out[i])      
            );
        end
    endgenerate

    assign fc1_valid = valid_out_arr[0];
endmodule