module sobel_soc_wrapper #(
    parameter PARALLEL_PIXELS = 32
)(
    input  logic         clk,
    input  logic         rst_n,

    // ----------------------------------------------------
    // Avalon-ST Sink
    // ----------------------------------------------------
    input  logic [255:0] asi_data,
    input  logic         asi_valid,
    output logic         asi_ready,

    // ----------------------------------------------------
    // Giao diện Avalon-ST Source 
    // ----------------------------------------------------
    output logic [255:0] aso_data,
    output logic         aso_valid,
    input  logic         aso_ready
);


    assign asi_ready = aso_ready;

    logic         sobel_valid_mid;
    logic [PARALLEL_PIXELS*72-1:0] sobel_window_array;

    parallel_line_buffer #(
        .IMG_WIDTH(640),
        .PIXELS_PER_CLK(PARALLEL_PIXELS)
    ) u_line_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(asi_valid && asi_ready), 
        .ready_in(aso_ready),
        .din(asi_data),
        .valid_out(sobel_valid_mid),
        .window_array_out(sobel_window_array)
    );

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
