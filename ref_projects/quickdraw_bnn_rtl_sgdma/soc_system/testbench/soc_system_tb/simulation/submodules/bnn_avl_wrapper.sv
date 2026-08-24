module bnn_avl_wrapper (
    input  logic        clk,
    input  logic        rst_n,

    // ---------------------------------------------------
    // Avalon Streaming Sink (Nhận data từ mSGDMA)
    // ---------------------------------------------------
    input  logic [31:0] avl_s_data,
    input  logic        avl_s_valid,
    output logic        avl_s_ready,

    // ---------------------------------------------------
    // Avalon Memory-Mapped Agent (HPS đọc kết quả)
    // ---------------------------------------------------
    input  logic [0:0]  avl_mm_address,  // Chỉ cần 1 bit địa chỉ cho 2 thanh ghi
    input  logic        avl_mm_read,
    output logic [31:0] avl_mm_readdata
  );

  // ===================================================
  // 1. Logic Serialization: 32-bit -> 1-bit
  // ===================================================
  logic [31:0] shift_reg;
  logic [5:0]  bit_cnt;
  logic        is_shifting;

  // Sẵn sàng nhận dữ liệu khi không bận dịch bit
  assign avl_s_ready = !is_shifting;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      shift_reg   <= '0;
      bit_cnt     <= '0;
      is_shifting <= 1'b0;
    end
    else
    begin
      if (avl_s_valid && avl_s_ready)
      begin
        // Load data 32-bit từ DMA
        shift_reg   <= avl_s_data;
        bit_cnt     <= 6'd32;
        is_shifting <= 1'b1;
      end
      else if (is_shifting)
      begin
        if (bit_cnt > 1)
        begin
          // Dịch trái từng bit
          shift_reg <= {1'b0, shift_reg[31:1]};
          bit_cnt   <= bit_cnt - 1'b1;
        end
        else
        begin
          is_shifting <= 1'b0; // Hoàn thành dịch 32 bit
        end
      end
    end
  end

  // ===================================================
  // 2. Kết nối với lõi BNN (bdscnn_top)
  // ===================================================
  logic       sys_valid;
  logic [3:0] class_out;

  bdscnn_top u_bdscnn (
               .clk       (clk),
               .rst_n     (rst_n),
               .img_valid (is_shifting),      // Valid khi đang bơm bit
               .img_data  (shift_reg[0]),     // Bơm bit LSB (hoặc MSB tùy thuật toán)
               .sys_valid (sys_valid),
               .class_out (class_out)
             );

  // ===================================================
  // 3. Avalon-MM Agent: Lưu và Đọc kết quả
  // ===================================================
  logic [31:0] result_reg;
  logic        done_flag;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      result_reg <= '0;
      done_flag  <= 1'b0;
    end
    else
    begin
      if (sys_valid)
      begin
        result_reg <= {28'd0, class_out}; // Chèn số 0 cho đủ 32-bit
        done_flag  <= 1'b1;
      end

      // Xóa cờ done_flag khi HPS đọc kết quả (Read-to-clear)
      if (avl_mm_read && avl_mm_address == 1'b0)
      begin
        done_flag <= 1'b0;
      end
    end
  end

  // Phân bổ địa chỉ cho HPS:
  // Offset 0x0: Đọc kết quả (Bit 31: done_flag, Bit 3-0: class_out)
  // Offset 0x4: Đọc trạng thái (Ví dụ: đang rảnh hay bận)
  always_comb
  begin
    if (avl_mm_read)
    begin
      case (avl_mm_address)
        1'b0:
          avl_mm_readdata = {done_flag, 31'd0} | result_reg;
        1'b1:
          avl_mm_readdata = {31'd0, is_shifting};
        default:
          avl_mm_readdata = 32'd0;
      endcase
    end
    else
    begin
      avl_mm_readdata = 32'd0;
    end
  end

endmodule
