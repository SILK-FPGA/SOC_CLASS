module buffer_hdmi (
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
    // HDMI READ SIDE
    // 1 bit/pixel
    // =====================================================
    input  logic         hdmi_clk_i,
    input  logic         hdmi_reset_i,
    input  logic         hdmi_enable_i,
    output logic         hdmi_data_o
);

    localparam int H_RES      = 32;
    localparam int V_RES      = 32;
    localparam int FRAME_BITS = H_RES * V_RES; // 1024 bit

    // 32 x 15 = 480
    localparam int DISPLAY_SCALE = 15;
    localparam int DISPLAY_W     = H_RES * DISPLAY_SCALE; // 480
    localparam int DISPLAY_H     = V_RES * DISPLAY_SCALE; // 480

    // Anh 480x480 nam giua vung active 640x480
    localparam int X_OFFSET = (640 - DISPLAY_W) / 2; // 80
    localparam int Y_OFFSET = (480 - DISPLAY_H) / 2; // 0

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
    //
    // Chi dong bo avl_done_o.
    // Sau khi avl_done_o = 1, frame_bits dung yen cho den
    // khi bat dau frame moi.
    // =====================================================
    logic avl_done_meta;
    logic avl_done_hdmi;

    always_ff @(posedge hdmi_clk_i) begin
        if (!rstn_i) begin
            avl_done_meta <= 1'b0;
            avl_done_hdmi <= 1'b0;
        end else begin
            avl_done_meta <= avl_done_o;
            avl_done_hdmi <= avl_done_meta;
        end
    end

    // =====================================================
    // HDMI ACTIVE-AREA COORDINATES
    // hdmi_enable_i chi cao trong vung active 640x480.
    // =====================================================
    logic [9:0] hdmi_x;
    logic [8:0] hdmi_y;

    logic       inside_image;
    logic [9:0] relative_x;
    logic [8:0] relative_y;
    logic [4:0] src_x;
    logic [4:0] src_y;
    logic [9:0] pixel_index;

    always_comb begin
        inside_image =
            (hdmi_x >= X_OFFSET) &&
            (hdmi_x <  X_OFFSET + DISPLAY_W) &&
            (hdmi_y >= Y_OFFSET) &&
            (hdmi_y <  Y_OFFSET + DISPLAY_H);

        relative_x = inside_image ? (hdmi_x - X_OFFSET) : 10'd0;
        relative_y = inside_image ? (hdmi_y - Y_OFFSET) :  9'd0;

        // Moi pixel nguon duoc lap 15 lan theo moi chieu.
        src_x = relative_x / DISPLAY_SCALE;
        src_y = relative_y / DISPLAY_SCALE;

        // pixel_index = src_y * 32 + src_x
        pixel_index = {src_y, 5'b0} + src_x;
    end

    // =====================================================
    // HDMI OUTPUT
    // =====================================================
    always_ff @(posedge hdmi_clk_i) begin
        if (!rstn_i) begin
            hdmi_x      <= 10'd0;
            hdmi_y      <= 9'd0;
            hdmi_data_o <= 1'b0;
        end

        // Xung reset frame do vga_hdmi tao ra.
        else if (hdmi_reset_i) begin
            hdmi_x      <= 10'd0;
            hdmi_y      <= 9'd0;
            hdmi_data_o <= 1'b0;
        end

        else if (hdmi_enable_i) begin
            if (avl_done_hdmi && inside_image) begin
                hdmi_data_o <= frame_bits[pixel_index];
            end else begin
                hdmi_data_o <= 1'b0;
            end

            // Dem toa do trong vung active 640x480.
            if (hdmi_x == 10'd639) begin
                hdmi_x <= 10'd0;

                if (hdmi_y == 9'd479) begin
                    hdmi_y <= 9'd0;
                end else begin
                    hdmi_y <= hdmi_y + 9'd1;
                end
            end else begin
                hdmi_x <= hdmi_x + 10'd1;
            end
        end

        else begin
            hdmi_data_o <= 1'b0;
        end
    end

endmodule
