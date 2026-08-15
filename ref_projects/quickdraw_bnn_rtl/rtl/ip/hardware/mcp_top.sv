module mcp_top (
    input  logic        clk,
    input  logic        rst_n,
    
    // Nguồn ảnh gốc
    input  logic        img_valid,
    input  logic        img_data, 
    
    // Đẩy sang lớp DW
    output logic        mcp_valid,
    output logic [2:0]  mcp_data_out // 3 kênh
);

    // ==========================================
    // 1. TẠO CỬA SỔ
    // ==========================================
    logic        win_valid;
    logic [15:0] win_data;

    window4x4s2 u_window (
        .clk         (clk),
        .rst_n       (rst_n),
        .din_valid   (img_valid),
        .din         (img_data),
        .dout_valid  (win_valid),
        .dout_window (win_data)
    );

    // ==========================================
    // 2. ROM TRỌNG SỐ & NGƯỠNG
    // ==========================================
    

    localparam logic [15:0] mcp_weights [0:2] = '{
        16'h2664,
        16'hccc0,
        16'hc000
    };

    localparam logic [16:0] mcp_thresh [0:2] = '{
        17'h10001,
        17'h10003,
        17'h10001
    };

    // ==========================================
    // 3. ĐÚC 3 LÕI MCP_PE (CHO 3 FILTERS)
    // ==========================================
    logic [2:0] valid_out_arr;

    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : gen_mcp_filters
            mcp_pe u_pe (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (win_valid),
                .window_in (win_data),
                .weight_in (mcp_weights[i]),
                .thresh_in (mcp_thresh[i]),
                .valid_out (valid_out_arr[i]),
                .data_out  (mcp_data_out[i])
            );
        end
    endgenerate

    // 3 core chạy đồng bộ, lấy cờ của core 0 làm đại diện
    assign mcp_valid = valid_out_arr[0];

endmodule