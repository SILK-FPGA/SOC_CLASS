module read_avalon_sdr #(
    parameter BASE_ADDRESS     = 32'h3000_0000,
    parameter IMAGE_SIZE_BYTES = 307200, // 640x480 = 307200 bytes
    parameter BURST_COUNT      = 4
)(
    input   logic         clk,
    input   logic         rst_n,

    // Giao tiếp Avalon-MM Read Master
    output  logic         avm_m0_read,
    output  logic [31:0]  avm_m0_address,
    input   logic [255:0] avm_m0_readdata,
    input   logic         avm_m0_readdatavalid,
    output  logic [31:0]  avm_m0_byteenable,
    input   logic         avm_m0_waitrequest,
    output  logic [10:0]  avm_m0_burstcount,

    // Giao tiếp ngoại vi (Control & Data Stream)
    input   logic         read_start_i,
    output  logic [255:0] read_data_o,
    output  logic         read_enable_o
);

    typedef enum logic [1:0] {
        INIT      = 2'd0,
        READ_REQ  = 2'd1, // Gửi yêu cầu đọc (Assert Read)
        READ_DATA = 2'd2  // Nhận dữ liệu (Wait for Data Valid)
    } state_t;
    
    state_t state, n_state;
    
    logic [31:0] address, n_address;
    logic [31:0] bytes_read, n_bytes_read; // Đếm tổng số byte đã đọc
    logic [10:0] beat_count, n_beat_count; // Đếm số beat trong 1 burst
    
    // Phát hiện sườn lên (Rising Edge Detector) cho tín hiệu start
    logic read_start_reg;
    logic read_start_rise;
    assign read_start_rise = ~read_start_reg & read_start_i;

    // Tín hiệu đầu ra tĩnh
    assign avm_m0_byteenable = 32'hFFFF_FFFF;
    assign avm_m0_burstcount = BURST_COUNT[10:0];
    assign avm_m0_address    = address;

    always_comb begin
        // Giá trị mặc định chống suy luận Latch
        n_state      = state;
        n_address    = address;
        n_bytes_read = bytes_read;
        n_beat_count = beat_count;
        
        avm_m0_read   = 1'b0;
        read_data_o   = '0;
        read_enable_o = 1'b0;

        case (state)
            INIT: begin
                if (read_start_rise) begin
                    n_state      = READ_REQ;
                    n_address    = BASE_ADDRESS;
                    n_bytes_read = '0;
                    n_beat_count = '0;
                end
            end
            
            READ_REQ: begin
                avm_m0_read = 1'b1;
                // Nếu bus không báo waitrequest nghĩa là lệnh đọc đã được chấp nhận
                if (!avm_m0_waitrequest) begin
                    n_state = READ_DATA;
                end
            end
            
            READ_DATA: begin
                if (avm_m0_readdatavalid) begin
                    // Bắn dữ liệu thẳng ra Line Buffer
                    read_data_o   = avm_m0_readdata;
                    read_enable_o = 1'b1;
                    
                    n_bytes_read = bytes_read + 32'd32; // Mỗi beat là 256-bit = 32 bytes
                    n_beat_count = beat_count + 1'b1;
                    
                    if (beat_count == BURST_COUNT - 1) begin
                        // Đã đọc đủ 1 burst
                        n_beat_count = '0;
                        n_address    = address + (BURST_COUNT * 32); 
                        
                        // Kiểm tra xem đã đọc hết ảnh chưa
                        if (bytes_read + 32'd32 >= IMAGE_SIZE_BYTES) begin
                            n_state = INIT;
                        end else begin
                            n_state = READ_REQ; // Quay lại xin đọc burst tiếp theo
                        end
                    end
                end
            end
            
            default: n_state = INIT;
        endcase
    end

    // Ghi nhận trạng thái tại sườn lên của Clock
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin   
            state          <= INIT;
            address        <= BASE_ADDRESS;
            bytes_read     <= '0;
            beat_count     <= '0;
            read_start_reg <= '0;
        end else begin
            state          <= n_state;
            address        <= n_address;
            bytes_read     <= n_bytes_read;
            beat_count     <= n_beat_count;
            read_start_reg <= read_start_i;
        end
    end

endmodule