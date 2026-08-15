module bnn_soc_wrapper (
    input  logic         clk,
    input  logic         reset,
    
    // PIO HPS (Control & Status)
    input  logic         read_start_i,
    output logic [31:0]  ai_result_word_o,
    
    // Avalon-MM Master to SDRAM
    output logic         avm_m0_read,
    output logic [31:0]  avm_m0_address,
    output logic [10:0]  avm_m0_burstcount,
    input  logic [255:0] avm_m0_readdata,
    input  logic         avm_m0_readdatavalid,
    input  logic         avm_m0_waitrequest
);

    // Dây nối nội bộ
    logic read_reset, read_enable, read_done;
    logic [255:0] read_data;
    
    logic img_valid, img_data;
    logic sys_valid;
    logic [3:0] class_out;
    
    logic avl_done;
    logic ai_rst_n;
    logic ai_busy;
    logic ai_stream_done;

    // 1. DMA Reader
    /* verilator lint_off PINCONNECTEMPTY */
    read_avalon_sdr u_dma (
        .clk(clk), 
        .reset(reset),
        .avm_m0_read(avm_m0_read), 
        .avm_m0_write(),              // Bỏ trống cố ý
        .avm_m0_writedata(),          // Bỏ trống cố ý
        .avm_m0_address(avm_m0_address),
        .avm_m0_readdata(avm_m0_readdata), 
        .avm_m0_readdatavalid(avm_m0_readdatavalid),
        .avm_m0_byteenable(),         // Bỏ trống cố ý
        .avm_m0_waitrequest(avm_m0_waitrequest),
        .avm_m0_burstcount(avm_m0_burstcount),
        .read_start_i(read_start_i), 
        .read_reset_o(read_reset),
        .read_data_o(read_data), 
        .read_enable_o(read_enable), 
        .read_done_o(read_done)
    );
    /* verilator lint_on PINCONNECTEMPTY */

    // 2. Buffer AI (Serializer)
    buffer_AI u_buffer (
        .rstn_i(~reset),
        .avl_clk_i(clk),
        .avl_reset_i(read_reset),
        .avl_data_i(read_data),
        .avl_enable_i(read_enable),
        .avl_done_o(avl_done),
        .ai_clk_i(clk),
        .ai_result_valid_i(sys_valid),
        .ai_rst_n_o(ai_rst_n),
        .img_valid_o(img_valid),
        .img_data_o(img_data),
        .ai_busy_o(ai_busy),
        .ai_stream_done_o(ai_stream_done)
    );

    // 3. AI Core
    bdscnn_top u_ai_core (
        .clk(clk), 
        .rst_n(ai_rst_n),      // Lấy reset nội bộ từ buffer nhả ra
        .img_valid(img_valid),
        .img_data(img_data), 
        .sys_valid(sys_valid), 
        .class_out(class_out)
    );

    // 4. CSR Status Register
    ai_result_register u_csr (
        .clk_i(clk), 
        .rstn_i(~reset),
        .new_frame_i(read_start_i),
        .result_valid_i(sys_valid), 
        .class_i(class_out),
        .ai_busy_i(ai_busy), 
        .stream_done_i(ai_stream_done), 
        .buffer_done_i(read_done),
        .result_word_o(ai_result_word_o)
    );

endmodule
