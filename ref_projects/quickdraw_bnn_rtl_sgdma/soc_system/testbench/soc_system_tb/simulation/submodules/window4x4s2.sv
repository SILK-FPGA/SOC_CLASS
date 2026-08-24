module window4x4s2 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        din_valid,
    input  logic        din,         // 1 pixel ảnh thô (1-bit)
    
    output logic        dout_valid,
    output logic [15:0] dout_window  // Cửa sổ 4x4 đã duỗi phẳng
);
    // 3 hàng đệm, mỗi hàng dài 32 pixel
    logic [31:0] row1, row2, row3;
    logic [15:0] window;
    
    // Bộ đếm quét ảnh 32x32
    logic [4:0]  col_cnt; 
    logic [4:0]  row_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row1       <= '0; 
            row2       <= '0; 
            row3       <= '0;
            window     <= '0;
            col_cnt    <= '0; 
            row_cnt    <= '0;
            dout_valid <= 1'b0;
        end else begin
            dout_valid <= 1'b0; 
            
            if (din_valid) begin
                // quản lý tọa độ (từ trái sang phải, trên xuống dưới)
                if (col_cnt == 5'd31) begin
                    col_cnt <= '0;
                    row_cnt <= row_cnt + 1'b1;
                end else begin
                    col_cnt <= col_cnt + 1'b1;
                end

                //dẩy dữ liệu qua line buffers (chờ 32 chu kỳ để rớt xuống hàng dưới)
                row1 <= {row1[30:0], din};
                row2 <= {row2[30:0], row1[31]};
                row3 <= {row3[30:0], row2[31]};

                //cập nhật cửa sổ 4x4 (dịch trái, nạp pixel mới vào bên phải)
                window[15:13] <= window[14:12]; window[12] <= row3[31]; // hàng xa nhất
                window[11:9]  <= window[10:8];  window[8]  <= row2[31]; 
                window[7:5]   <= window[6:4];   window[4]  <= row1[31]; 
                window[3:1]   <= window[2:0];   window[0]  <= din;      // hàng hiện tại

                // valid logic (stride = 2)
                // cửa sổ đầy khi row >=3 và col >=3. 
                // lấy các tọa độ le (3, 5, 7... 31) bằng cách xét bit LSB (bit [0] == 1)
                if (row_cnt >= 3 && col_cnt >= 3 && row_cnt[0] == 1'b1 && col_cnt[0] == 1'b1) begin
                    dout_valid <= 1'b1;
                end
            end
        end
    end

    // dảo ngược vị trí bit để pixel góc trên-trái về LSB, khớp với PyTorch Flatten
    assign dout_window = {window[0],  window[1],  window[2],  window[3],
                          window[4],  window[5],  window[6],  window[7],
                          window[8],  window[9],  window[10], window[11],
                          window[12], window[13], window[14], window[15]};

endmodule