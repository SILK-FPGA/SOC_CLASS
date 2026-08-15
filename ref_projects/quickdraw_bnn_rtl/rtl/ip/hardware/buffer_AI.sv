module buffer_AI (
    input  logic         rstn_i,

    // =====================================================
    // AVALON WRITE SIDE
    // 4 beat x 256 bit = 1024 bit = anh 32x32
    // =====================================================
    input  logic         avl_clk_i,
    input  logic         avl_reset_i,
    input  logic [255:0] avl_data_i,
    input  logic         avl_enable_i,
    output logic         avl_done_o,

    // =====================================================
    // AI STREAM SIDE
    // =====================================================
    input  logic         ai_clk_i,

    // sys_valid tu bdscnn_top noi nguoc ve day.
    input  logic         ai_result_valid_i,

    // Noi sang bdscnn_top.
    output logic         ai_rst_n_o,
    output logic         img_valid_o,
    output logic         img_data_o,

    // Tin hieu trang thai.
    output logic         ai_busy_o,
    output logic         ai_stream_done_o
);

    localparam int FRAME_BITS = 32 * 32; // 1024 bit

    // =====================================================
    // FRAME BUFFER
    //
    // frame_bits[0]    = pixel (0,0)
    // frame_bits[31]   = pixel (31,0)
    // frame_bits[32]   = pixel (0,1)
    // frame_bits[1023] = pixel (31,31)
    //
    // Nen den = 0, net trang = 1.
    // Dinh dang packed row-major, LSB-first.
    // =====================================================
    logic [FRAME_BITS-1:0] frame_bits;

    // =====================================================
    // AVALON WRITE CONTROL
    // =====================================================
    logic [2:0] avl_count;
    logic       avl_reset_d;
    logic       avl_reset_rise;

    assign avl_reset_rise = avl_reset_i & ~avl_reset_d;

    always_ff @(posedge avl_clk_i) begin
        if (!rstn_i) begin
            avl_reset_d <= 1'b0;
            avl_count   <= 3'd0;
            avl_done_o  <= 1'b0;
            frame_bits  <= '0;
        end else begin
            avl_reset_d <= avl_reset_i;

            // Bat dau frame moi.
            if (avl_reset_rise) begin
                avl_done_o <= 1'b0;

                // Neu reset va beat dau trung chu ky,
                // van luu beat dau thay vi bo qua.
                if (avl_enable_i) begin
                    frame_bits[255:0] <= avl_data_i;
                    avl_count         <= 3'd1;
                end else begin
                    avl_count <= 3'd0;
                end
            end

            // Ghi cac beat con lai.
            else if (avl_enable_i && !avl_done_o) begin
                case (avl_count)
                    3'd0: frame_bits[ 255:  0] <= avl_data_i;
                    3'd1: frame_bits[ 511:256] <= avl_data_i;
                    3'd2: frame_bits[ 767:512] <= avl_data_i;
                    3'd3: frame_bits[1023:768] <= avl_data_i;
                    default: ;
                endcase

                if (avl_count == 3'd3) begin
                    avl_done_o <= 1'b1;
                end else begin
                    avl_count <= avl_count + 3'd1;
                end
            end
        end
    end

    // =====================================================
    // CLOCK DOMAIN CROSSING
    // Dong bo frame-ready sang ai_clk_i.
    // =====================================================
    logic avl_done_meta;
    logic avl_done_ai;
    logic avl_done_ai_d;
    logic avl_done_ai_rise;

    assign avl_done_ai_rise = avl_done_ai & ~avl_done_ai_d;

    always_ff @(posedge ai_clk_i) begin
        if (!rstn_i) begin
            avl_done_meta <= 1'b0;
            avl_done_ai   <= 1'b0;
            avl_done_ai_d <= 1'b0;
        end else begin
            avl_done_meta <= avl_done_o;
            avl_done_ai   <= avl_done_meta;
            avl_done_ai_d <= avl_done_ai;
        end
    end

    // Ban sao frame dung rieng trong mien clock AI.
    logic [FRAME_BITS-1:0] ai_frame_bits;

    // =====================================================
    // AI STREAM FSM
    // =====================================================
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_SETTLE,
        ST_RELEASE_RESET,
        ST_STREAM,
        ST_WAIT_RESULT,
        ST_HOLD
    } state_t;

    state_t state;

    logic [1:0] settle_count;
    logic [9:0] pixel_index;

    always_comb begin
        case (state)
            ST_SETTLE,
            ST_RELEASE_RESET,
            ST_STREAM,
            ST_WAIT_RESULT: ai_busy_o = 1'b1;

            default:        ai_busy_o = 1'b0;
        endcase
    end

    always_ff @(posedge ai_clk_i) begin
        if (!rstn_i) begin
            state            <= ST_IDLE;
            settle_count     <= 2'd0;
            pixel_index      <= 10'd0;
            ai_frame_bits    <= '0;

            ai_rst_n_o       <= 1'b0;
            img_valid_o      <= 1'b0;
            img_data_o       <= 1'b0;
            ai_stream_done_o <= 1'b0;
        end else begin
            // Hai tin hieu nay la pulse/default-low.
            img_valid_o      <= 1'b0;
            ai_stream_done_o <= 1'b0;

            // Khi frame moi dang duoc ghi, avl_done_ai ve 0.
            // Reset AI va quay lai trang thai cho.
            if (!avl_done_ai) begin
                state         <= ST_IDLE;
                settle_count  <= 2'd0;
                pixel_index   <= 10'd0;
                ai_rst_n_o    <= 1'b0;
                img_data_o    <= 1'b0;
            end else begin
                case (state)

                    // Cho canh len bao nhan du 4 beat.
                    ST_IDLE: begin
                        ai_rst_n_o  <= 1'b0;
                        pixel_index <= 10'd0;

                        if (avl_done_ai_rise) begin
                            settle_count <= 2'd0;
                            state        <= ST_SETTLE;
                        end
                    end

                    // Cho frame_bits on dinh sau CDC,
                    // sau do chup toan bo frame.
                    ST_SETTLE: begin
                        ai_rst_n_o <= 1'b0;

                        if (settle_count == 2'd2) begin
                            ai_frame_bits <= frame_bits;
                            settle_count  <= 2'd0;
                            state         <= ST_RELEASE_RESET;
                        end else begin
                            settle_count <= settle_count + 2'd1;
                        end
                    end

                    // Nha reset AI mot clock truoc pixel dau.
                    ST_RELEASE_RESET: begin
                        ai_rst_n_o  <= 1'b1;
                        pixel_index <= 10'd0;
                        state       <= ST_STREAM;
                    end

                    // Phat dung 1024 pixel, 1 bit moi clock.
                    ST_STREAM: begin
                        ai_rst_n_o  <= 1'b1;
                        img_valid_o <= 1'b1;
                        img_data_o  <= ai_frame_bits[pixel_index];

                        if (pixel_index == 10'd1023) begin
                            pixel_index      <= 10'd0;
                            ai_stream_done_o <= 1'b1;
                            state            <= ST_WAIT_RESULT;
                        end else begin
                            pixel_index <= pixel_index + 10'd1;
                        end
                    end

                    // Da phat het input, tiep tuc giu AI khoi reset
                    // de pipeline xu ly den khi sys_valid len.
                    ST_WAIT_RESULT: begin
                        ai_rst_n_o <= 1'b1;

                        if (ai_result_valid_i) begin
                            state <= ST_HOLD;
                        end
                    end

                    // Da co ket qua. Khong phat lai frame cu.
                    // Cho frame moi lam avl_done_ai ve 0.
                    ST_HOLD: begin
                        ai_rst_n_o <= 1'b0;
                    end

                    default: begin
                        state         <= ST_IDLE;
                        ai_rst_n_o    <= 1'b0;
                        img_data_o    <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
