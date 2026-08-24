`timescale 1ns/1ps

module tb_soc_master();

  // Khai báo xung nhịp và reset toàn hệ thống
  logic clk;
  logic reset_n;

  initial begin
    clk = 0;
    forever #10 clk = ~clk; // Clock 50MHz
  end

  initial begin
    reset_n = 0;
    #100;
    reset_n = 1; // Nhả reset sau 100ns
  end

  // Instantiation soc_system_tb (Khối Top mà Qsys vừa generate)
  soc_system_tb u_soc_tb (
    .clk_clk                (clk),
    .reset_reset_n          (reset_n),
    .memory_mem_a           (), 
    .memory_mem_ba          (),
    .memory_mem_cas_n       (),
    .memory_mem_ck          (),
    .memory_mem_ck_n        (),
    .memory_mem_cke         (),
    .memory_mem_cs_n        (),
    .memory_mem_dm          (),
    .memory_mem_dq          (),
    .memory_mem_dqs         (),
    .memory_mem_dqs_n       (),
    .memory_mem_odt         (),
    .memory_mem_ras_n       (),
    .memory_mem_reset_n     (),
    .memory_mem_we_n        (),
    .memory_mem_oct_rzqin   (1'b1)
  );

  // Mảng lưu trữ ảnh tạm thời trong TB
  logic        mem_img [0:1023];
  logic [31:0] packed_word;
  integer      i, j;

  // Mô phỏng luồng thực thi của phần mềm C (Chạy song song với phần cứng)
  initial begin
    // 1. Chờ hệ thống ổn định sau khi thoát reset
    @(posedge reset_n);
    #500;

    $display("========================================================");
    $display("[SOC_SIM] Bắt đầu nạp ảnh test_img_0.txt vào SDRAM giả lập...");
    $display("========================================================");

    // 2. Đọc file ảnh thô và pack bit theo chuẩn LSB-first y hệt code C
    $readmemb("/home/huyatieo/Desktop/project/bnn_soc/fpga_test_vectors/test_img_0.txt", mem_img);

    for (i = 0; i < 32; i++) begin
      packed_word = 32'd0;
      for (j = 0; j < 32; j++) begin
        if (mem_img[i*32 + j] == 1'b1) begin
          packed_word[j] = 1'b1;
        end
      end
      
      // Ghi trực tiếp vào không gian bộ nhớ SDRAM thông qua Avalon-MM Master BFM
      write_sdram_word(32'h30000000 + (i * 4), packed_word);
    end

    $display("[SOC_SIM] Đã ghi xong 32 words vào SDRAM. Tiến hành cấu hình mSGDMA...");

    // 3. Cấu hình mSGDMA qua giao tiếp Lightweight Bridge (0xFF200000)
    // Reset mSGDMA CSR Control Register
    write_lw_mm(32'h0004, 32'h00000002); 
    #200;
    write_lw_mm(32'h0004, 32'h00000000); 

    // Ghi Descriptor: Read Address = 0x30000000, Length = 128 bytes (32 words)
    write_lw_mm(32'h0020, 32'h30000000); // DESCR_READ_ADDR
    write_lw_mm(32'h0024, 32'h00000000); // DESCR_WRITE_ADDR
    write_lw_mm(32'h0028, 32'h00000080); // DESCR_LENGTH (128 bytes)
    
    // Kích hoạt lệnh GO kèm SOP và EOP
    write_lw_mm(32'h002C, 32'h80000300); // DESCR_CONTROL (GO=1, Gen_SOP=1, Gen_EOP=1)

    $display("[SOC_SIM] mSGDMA đã bắt đầu bắn dữ liệu streaming sang BNN Wrapper...");

    // 4. Polling thanh ghi kết quả BNN tại Offset 0x0030
    wait_bnn_result();

    $display("========================================================");
    $display("[SOC_SIM] MÔ PHỎNG TOÀN BỘ SOC HOÀN TẤT THÀNH CÔNG!");
    $display("========================================================");
    $finish;
  end

  // --- Các hàm Task trỏ đúng đường dẫn BFM của Qsys ---
  task write_lw_mm(input [31:0] offset, input [31:0] data);
    begin
      u_soc_tb.soc_system_inst.hps_0_h2f_lw_axi_master_agent.drv.avm_if.write(offset, data, 4);
    end
  endtask

  task write_sdram_word(input [31:0] addr, input [31:0] data);
    begin
      u_soc_tb.soc_system_inst.hps_0_f2h_sdram0_data_agent.drv.avm_if.write(addr - 32'h30000000, data, 4);
    end
  endtask

  task wait_bnn_result();
    logic [31:0] readdata;
    begin
      readdata = 32'h0;
      while (readdata[31] == 1'b0) begin
        #100;
        u_soc_tb.soc_system_inst.hps_0_h2f_lw_axi_master_agent.drv.avm_if.read(32'h0030, 4, readdata);
      end
      $display("🎯 [SOC_SIM] BNN đã tính toán xong! Kết quả Class trả về: %0d", readdata[3:0]);
    end
  endtask

endmodule