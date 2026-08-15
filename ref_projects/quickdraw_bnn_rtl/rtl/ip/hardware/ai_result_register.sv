module ai_result_register (
    input  logic        clk_i,
    input  logic        rstn_i,

    input  logic        new_frame_i,

    input  logic        result_valid_i,
    input  logic [3:0]  class_i,

    input  logic        ai_busy_i,
    input  logic        stream_done_i,
    input  logic        buffer_done_i,

    output logic [31:0] result_word_o
);

    logic [3:0] class_latched;
    logic       valid_latched;
    logic [7:0] result_sequence;

    // Dùng để phát hiện cạnh lên của result_valid_i
    logic result_valid_d;
    logic result_valid_rise;

    assign result_valid_rise =
        result_valid_i & ~result_valid_d;

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            result_valid_d <= 1'b0;
        end else begin
            result_valid_d <= result_valid_i;
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            class_latched   <= 4'd0;
            valid_latched   <= 1'b0;
            result_sequence <= 8'd0;
        end else begin
            // Bắt đầu ảnh mới: kết quả cũ không còn hợp lệ
            if (new_frame_i) begin
                valid_latched <= 1'b0;
            end

            // Chỉ chốt tại cạnh lên của sys_valid
            if (result_valid_rise) begin
                class_latched   <= class_i;
                valid_latched   <= 1'b1;
                result_sequence <= result_sequence + 8'd1;
            end
        end
    end

    always_comb begin
        result_word_o = 32'd0;

        result_word_o[31]    = valid_latched;
        result_word_o[30]    = ai_busy_i;
        result_word_o[29]    = stream_done_i;
        result_word_o[28]    = buffer_done_i;
        result_word_o[23:16] = result_sequence;
        result_word_o[3:0]   = class_latched;
    end

endmodule
