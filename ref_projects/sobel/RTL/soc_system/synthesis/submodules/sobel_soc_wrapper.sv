module sobel_soc_wrapper #(
    parameter PARALLEL_PIXELS = 32
)(
    input  logic         clk,
    input  logic         rst_n,

    // ----------------------------------------------------
    // Giao diện Avalon-ST Sink (Nhận luồng ảnh gốc từ mSGDMA Đọc)
    // ----------------------------------------------------
    input  logic [255:0] asi_data,
    input  logic         asi_valid,
    output logic         asi_ready,

    // ----------------------------------------------------
    // Giao diện Avalon-ST Source (Đẩy luồng kết quả ra mSGDMA Ghi)
    // ----------------------------------------------------
    output logic [255:0] aso_data,
    output logic         aso_valid,
    input  logic         aso_ready
);

    // ====================================================
    // QUẢN LÝ ÁP LỰC NGƯỢC (BACKPRESSURE)
    // ====================================================
    // Mạch Line Buffer hiện tại không có cơ chế dừng (stall) giữa chừng.
    // Tạm thời cho phép mạch luôn nhận dữ liệu nếu mSGDMA phía sau cũng sẵn sàng.
    assign asi_ready = aso_ready;

    // ====================================================
    // DÂY TÍN HIỆU NỘI BỘ
    // ====================================================
    logic         sobel_valid_mid;
    logic [PARALLEL_PIXELS*72-1:0] sobel_window_array;

    // ====================================================
    // 1. Parallel Line Buffer (Nuốt 256-bit, nhả 32 cửa sổ 3x3)
    // ====================================================
    parallel_line_buffer #(
        .IMG_WIDTH(640),
        .PIXELS_PER_CLK(PARALLEL_PIXELS)
    ) u_line_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(asi_valid && asi_ready), // Chỉ nhận khi cả 2 phía đồng thuận
        .ready_in(aso_ready),
        .din(asi_data),
        .valid_out(sobel_valid_mid),
        .window_array_out(sobel_window_array)
    );

    // ====================================================
    // 2. Sobel Accelerator Array (32 Lõi chạy song song)
    // ====================================================
    sobel_accelerator #(
        .PARALLEL_PIXELS(PARALLEL_PIXELS)
    ) u_sobel_array (
        .clk(clk),
        .rst_n(rst_n),
        .ready_in(aso_ready),
        .valid_in(sobel_valid_mid),
        .window_3x3_array_in(sobel_window_array),
        .valid_out(aso_valid),
        .pixels_out(aso_data)
    );

endmodule
