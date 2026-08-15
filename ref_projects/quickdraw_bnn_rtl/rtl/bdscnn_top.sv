import fc1_constants::*;
module bdscnn_top (
    input  logic         clk,
    input  logic         rst_n,

    // Cổng nạp ảnh Streaming (1 bit/chu kỳ)
    input  logic         img_valid,
    input  logic         img_data, 
    

    output logic         sys_valid,
    output logic [3:0]   class_out    // 10 class
);

   
    logic        mcp_valid;
    logic [2:0]  mcp_data;
    
    logic        dw_valid;
    logic [11:0] dw_data;
    
    logic        pw_valid;
    logic [17:0] pw_data;
    
    logic        fc1_valid;
    logic [63:0] fc1_data;

    // Trạm 1: Merged Conv-Pool
    mcp_top u_mcp (
        .clk          (clk),
        .rst_n        (rst_n),
        .img_valid    (img_valid),
        .img_data     (img_data),
        .mcp_valid    (mcp_valid),
        .mcp_data_out (mcp_data)
    );

    // Trạm 2: Depthwise
    dw_top u_dw (
        .clk          (clk),
        .rst_n        (rst_n),
        .mcp_valid    (mcp_valid),
        .mcp_data     (mcp_data),
        .dw_valid     (dw_valid),
        .dw_data_out  (dw_data)
    );

    // Trạm 3: Pointwise
    pw_top u_pw (
        .clk          (clk),
        .rst_n        (rst_n),
        .dw_valid     (dw_valid),
        .dw_data      (dw_data),
        .pw_valid     (pw_valid),
        .pw_data_out  (pw_data)
    );

    // Trạm 4: Fully Connected 1
    fc1_folded_top u_fc1 (
        .clk          (clk),
        .rst_n        (rst_n),
        .pw_valid     (pw_valid),
        .pw_data      (pw_data),
        .fc1_valid    (fc1_valid),
        .fc1_data_out (fc1_data)
    );

    // Trạm 5: Classifier FC2
    fc2_top u_fc2 (
        .clk          (clk),
        .rst_n        (rst_n),
        .fc1_valid    (fc1_valid),
        .fc1_data_in  (fc1_data),
        .fc2_valid    (sys_valid),
        .class_out    (class_out)
    );

endmodule