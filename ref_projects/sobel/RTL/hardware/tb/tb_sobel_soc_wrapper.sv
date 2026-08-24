`timescale 1ns/1ps

module tb_sobel_soc_wrapper();
    localparam IMG_WIDTH      = 640;
    localparam PIXELS_PER_CLK = 32;
    localparam WORDS_PER_LINE = IMG_WIDTH / PIXELS_PER_CLK; // 20 beats/line
    localparam TOTAL_INPUT    = 100;
    localparam EXPECTED_OUT   = TOTAL_INPUT - (2 * WORDS_PER_LINE); // 100 - 40 = 60 beats

    logic clk = 0;
    logic rst_n = 0;
    
    logic [255:0] asi_data = '0;
    logic         asi_valid = 0;
    logic         asi_ready;
    
    logic [255:0] aso_data;
    logic         aso_valid;
    logic         aso_ready = 0;

    sobel_soc_wrapper #(
        .PARALLEL_PIXELS(PIXELS_PER_CLK)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .asi_data  (asi_data),
        .asi_valid (asi_valid),
        .asi_ready (asi_ready),
        .aso_data  (aso_data),
        .aso_valid (aso_valid),
        .aso_ready (aso_ready)
    );

    always #10 clk = ~clk;

    int input_beats = 0;
    int output_beats = 0;

    initial begin
        $display("=== BAT DAU SIMULATION CHUAN ===");
        #50 rst_n = 1;
        
        fork
            // TIẾN TRÌNH 1: Gửi 100 beats tuân thủ Handshake (valid & ready)
            begin
                while (input_beats < TOTAL_INPUT) begin
                    @(posedge clk);
                    asi_valid <= 1'b1;
                    asi_data  <= asi_data + 1;
                    
                    if (asi_valid && asi_ready) begin
                        input_beats++;
                    end
                end
                @(posedge clk);
                asi_valid <= 1'b0;
            end
            
            // TIẾN TRÌNH 2: Tạo Backpressure và thu nhận đủ số beat mong đợi
            begin
                while (output_beats < EXPECTED_OUT) begin
                    @(posedge clk);
                    aso_ready <= ($urandom() % 100 < 70); // 70% sẵn sàng, 30% stall
                    
                    if (aso_valid && aso_ready) begin
                        output_beats++;
                    end
                end
            end
        join // Đợi CẢ HAI tiến trình hoàn tất thành công

        @(posedge clk);
        $display("========================================");
        $display("Tong so Beat gui vao : %d", input_beats);
        $display("So Beat giu trong line buffer: %d", 2 * WORDS_PER_LINE);
        $display("So Beat thuc te nhan : %d / %d (Ky vong)", output_beats, EXPECTED_OUT);
        
        if (output_beats == EXPECTED_OUT)
            $display("[THANH CONG] PIPELINE MATCH 100%% KHONG ROT DU LIEU!");
        else
            $display("[THAT BAI] DU LIEU BI THAT THOAT!");
        $display("========================================");
        $finish;
    end
endmodule