module write_avalon_sdr  #(
    parameter OUTPUT_BASE_ADDR = 32'h3100_0000, // Địa chỉ RAM lưu ảnh kết quả
    parameter IMAGE_SIZE_BYTES = 307200,        // Ví dụ: 640x480 = 307200 bytes
    parameter FIFO_DEPTH_LOG2  = 8              // FIFO sâu 256 từ (256 * 32 bytes = 8KB)
)(
    input  logic         clk,
    input  logic         rst_n,
    
    // Giao tiếp với Sobel Accelerator (Data Sink)
    input  logic         valid_in,
    input  logic [255:0] data_in,
    
    // Giao tiếp Avalon-MM Master (Đẩy ra RAM)
    output logic [31:0]  avm_m1_address,
    output logic         avm_m1_write,
    output logic [255:0] avm_m1_writedata,
    output logic [31:0]  avm_m1_byteenable,
    output logic [10:0]  avm_m1_burstcount,
    input  logic         avm_m1_waitrequest,
    
    // Tín hiệu báo cáo lên CPU (Thông qua CSR)
    output logic         frame_done
);
    localparam ACTUAL_EXPECTED_BYTES = IMAGE_SIZE_BYTES - 1280;
    // 1. Cấu trúc FIFO nội bộ (Hấp thụ xung đột tốc độ)
    logic [255:0] fifo_mem [0:(1<<FIFO_DEPTH_LOG2)-1];
    logic [FIFO_DEPTH_LOG2:0] wr_ptr, rd_ptr;
    logic empty;
    
    assign empty = (wr_ptr == rd_ptr);
    
    // Ghi vào FIFO từ Sobel
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (valid_in) begin
            fifo_mem[wr_ptr[FIFO_DEPTH_LOG2-1:0]] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
            // Lưu ý: Đề phòng tràn FIFO (Over-run) nếu băng thông ghi vào SDRAM 
            // trung bình thấp hơn tốc độ sinh dữ liệu của Sobel.
        end
    end

    // 2. Avalon-MM Write Master State Machine
    logic [31:0] current_address;
    logic [31:0] bytes_written;
    logic [21:0] done_timer; // Bộ đếm timer 22-bit (chứa được > 2.5 triệu)

    // Các tín hiệu cố định cho Write Single-Beat
    assign avm_m1_byteenable = 32'hFFFF_FFFF; 
    assign avm_m1_burstcount = 11'd1;         
    assign avm_m1_address    = current_address;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr          <= '0;
            avm_m1_write    <= 1'b0;
            avm_m1_writedata<= '0;
            current_address <= OUTPUT_BASE_ADDR;
            bytes_written   <= '0;
            frame_done      <= 1'b0;
            done_timer      <= '0;
        end else begin
            
            // Xử lý Timer để giữ cờ Done
            if (done_timer > 0) begin
                done_timer <= done_timer - 1'b1;
                if (done_timer == 1) frame_done <= 1'b0; // Hết giờ mới chịu hạ cờ
            end

            if (avm_m1_write) begin
                // Đang có yêu cầu ghi trên bus
                if (!avm_m1_waitrequest) begin
                    avm_m1_write <= 1'b0;
                    current_address <= current_address + 32'd32; 
                    bytes_written   <= bytes_written + 32'd32;
                    
                    // Kiểm tra chốt frame
                    if (bytes_written + 32'd32 >= ACTUAL_EXPECTED_BYTES) begin
                        frame_done      <= 1'b1; 
                        done_timer      <= 22'd2500000; // Căng cờ Done lên và giữ trong 50ms (2.5 triệu xung clock)
                        current_address <= OUTPUT_BASE_ADDR; 
                        bytes_written   <= '0;
                    end
                end
            end else if (!empty) begin
                // Nếu Bus rảnh và FIFO có dữ liệu -> Bắn dữ liệu ra
                avm_m1_write     <= 1'b1;
                avm_m1_writedata <= fifo_mem[rd_ptr[FIFO_DEPTH_LOG2-1:0]];
                rd_ptr           <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
