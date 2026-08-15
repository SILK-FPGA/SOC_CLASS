module fc1_folded_top_test (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         pw_valid,
    input  logic [17:0]  pw_data,
    output logic         fc1_valid,
    output logic [63:0]  fc1_data_out
);

   
     logic [3042:0] fc1_weights [0:63];
     logic [16:0]   fc1_thresh  [0:63];

    initial begin
        // Đường dẫn tuyệt đối 
        $readmemh("/home/ctw-fpga/Desktop/project/BNN/quick_draw/RTL/tb/fc1_weights.txt", fc1_weights);
        $readmemh("/home/ctw-fpga/Desktop/project/BNN/quick_draw/RTL/tb/fc1_thresh.txt", fc1_thresh);
    end

    // 2. MÁY TRẠNG THÁI QUÉT (Giữ nguyên)
    logic [7:0] pixel_cnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) pixel_cnt <= '0;
        else if (pw_valid) begin
            if (pixel_cnt == 8'd168) pixel_cnt <= '0;
            else pixel_cnt <= pixel_cnt + 1'b1;
        end
    end

    // 3. NHÂN BẢN 64 NƠ-RON
    logic [63:0] valid_out_arr;
    
    genvar i;
    generate
        for (i = 0; i < 63; i++) begin : gen_fc1_neurons
            // Móc trọng số từ mảng đã đọc được
            logic [17:0] current_weight_fm;
            assign current_weight_fm = fc1_weights[i][pixel_cnt * 18 +: 18];

            fc1_folded_neuron u_neuron (
                .clk       (clk),
                .rst_n     (rst_n),
                .pw_valid  (pw_valid),
                .pixel_cnt (pixel_cnt),
                .pw_data   (pw_data),
                .weight_fm (current_weight_fm),
                .thresh_in (fc1_thresh[i]),
                .valid_out (valid_out_arr[i]),
                .data_out  (fc1_data_out[i])
            );
        end
    endgenerate

    assign fc1_valid = valid_out_arr[0];

endmodule