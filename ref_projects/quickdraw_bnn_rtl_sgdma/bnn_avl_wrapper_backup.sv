module bnn_avl_wrapper (
    input  logic        clk,
    input  logic        rst_n,

    // ---------------------------------------------------
    // Avalon Streaming Sink (Nhận từ mSGDMA)
    // ---------------------------------------------------
    input  logic [31:0] avl_s_data,
    input  logic        avl_s_valid,
    output logic        avl_s_ready,

    // ---------------------------------------------------
    // Avalon Memory-Mapped Agent (HPS đọc/ghi CSR)
    // ---------------------------------------------------
    input  logic [2:0]  avl_mm_address,   // Mở rộng lên 3-bit để có 8 thanh ghi
    input  logic        avl_mm_read,
    input  logic        avl_mm_write,     // Bổ sung Write để CPU điều khiển
    input  logic [31:0] avl_mm_writedata,
    output logic [31:0] avl_mm_readdata
);

  // ===================================================
  // 0. THANH GHI ĐIỀU KHIỂN TỪ HPS (CSR WRITE)
  // ===================================================
  logic sw_soft_reset; // CPU chủ động kích hoạt reset

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sw_soft_reset <= 1'b0;
    end else begin
      // Tự động clear soft reset sau 1 xung nhịp
      if (sw_soft_reset) sw_soft_reset <= 1'b0; 
      else if (avl_mm_write && avl_mm_address == 3'd5) begin
        sw_soft_reset <= avl_mm_writedata[0];
      end
    end
  end

  // Tín hiệu reset tổng hợp (Gom cả Hard Reset và Soft Reset từ CPU)
  logic global_rst_n;
  assign global_rst_n = rst_n & ~sw_soft_reset;

  // ===================================================
  // 1. RAM ĐỆM ẢNH & QUẢN LÝ TRẠNG THÁI
  // ===================================================
  logic [31:0] img_buf [0:31];
  logic [5:0]  rx_word_idx; 
  logic        rx_done;
  logic [31:0] debug_total_rx_beats; // Debug: Đếm tổng số nhịp valid nhận được

  // Báo Ready khi chưa đầy buffer và không bị cấm bởi BNN
  assign avl_s_ready = !rx_done; 

  // ===================================================
  // 2. MÔ PHỎNG TIMING & AUTO-RESET LÕI BNN
  // ===================================================
  logic [5:0]  tx_word_idx;
  logic [5:0]  bit_cnt;
  logic [31:0] shift_reg;
  logic        is_shifting;
  
  logic        bnn_rst_n; // Soft Reset cho lõi BNN

  always_ff @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n) begin
      rx_word_idx          <= '0;
      rx_done              <= 1'b0;
      debug_total_rx_beats <= '0;
      tx_word_idx          <= '0;
      bit_cnt              <= '0;
      is_shifting          <= 1'b0;
      shift_reg            <= '0;
      bnn_rst_n            <= 1'b0;
    end else begin
      
      // --- ĐẾM DEBUG ---
      if (avl_s_valid && avl_s_ready) begin
        debug_total_rx_beats <= debug_total_rx_beats + 1'b1;
      end

      // --- GIAI ĐOẠN 1: Hút 32 Words từ DMA ---
      if (avl_s_valid && avl_s_ready) begin
        img_buf[rx_word_idx] <= avl_s_data;
        if (rx_word_idx == 6'd31) begin
          rx_done   <= 1'b1;
          bnn_rst_n <= 1'b1; // Kích hoạt BNN
        end
        rx_word_idx <= rx_word_idx + 1'b1;
      end

      // --- GIAI ĐOẠN 2: Bơm data vào BNN ---
      if (rx_done && bnn_rst_n) begin 
        if (!is_shifting) begin
          if (tx_word_idx < 6'd32) begin
            shift_reg   <= img_buf[tx_word_idx];
            bit_cnt     <= 6'd32;
            is_shifting <= 1'b1;
            tx_word_idx <= tx_word_idx + 1'b1;
          end
        end else begin
          if (bit_cnt > 1) begin
            shift_reg <= {1'b0, shift_reg[31:1]};
            bit_cnt   <= bit_cnt - 1'b1;
          end else begin
            is_shifting <= 1'b0; 
          end
        end
      end
      
      // --- GIAI ĐOẠN 3: Auto-clear sau khi tính xong ---
      if (sys_valid) begin
        rx_done     <= 1'b0;
        rx_word_idx <= '0;
        tx_word_idx <= '0;
        bnn_rst_n   <= 1'b0; 
      end
    end
  end

  // ===================================================
  // 3. KẾT NỐI VỚI LÕI BNN
  // ===================================================
  logic        sys_valid;
  logic [3:0]  class_out;

  bdscnn_top u_bdscnn (
      .clk       (clk),
      .rst_n     (bnn_rst_n), 
      .img_valid (is_shifting),
      .img_data  (shift_reg[0]), 
      .sys_valid (sys_valid),
      .class_out (class_out)
  );

  // ===================================================
  // 4. CSR READ MUX (Hỗ trợ Debug)
  // ===================================================
  logic [31:0] result_reg;
  logic        done_flag;

  always_ff @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n) begin
      result_reg <= '0;
      done_flag  <= 1'b0;
    end else begin
      if (sys_valid) begin
        result_reg <= {28'd0, class_out};
        done_flag  <= 1'b1;
      end else if (avl_mm_read && avl_mm_address == 3'd0) begin
        done_flag  <= 1'b0; // Clear on read (Clear-on-Read mechanism)
      end
    end
  end

  always_comb begin
    avl_mm_readdata = 32'd0;
    if (avl_mm_read) begin
      case (avl_mm_address)
        3'd0: avl_mm_readdata = {done_flag, 31'd0} | result_reg;
        3'd1: avl_mm_readdata = {28'd0, avl_s_ready, bnn_rst_n, rx_done, is_shifting};
        3'd2: avl_mm_readdata = {26'd0, rx_word_idx};
        3'd3: avl_mm_readdata = debug_total_rx_beats;
        3'd4: avl_mm_readdata = {20'd0, tx_word_idx, 6'd0} | {26'd0, bit_cnt};
        3'd5: avl_mm_readdata = {31'd0, sw_soft_reset};
        default: avl_mm_readdata = 32'hDEADBEEF; // Bắt lỗi đọc sai địa chỉ
      endcase
    end
  end

endmodule
