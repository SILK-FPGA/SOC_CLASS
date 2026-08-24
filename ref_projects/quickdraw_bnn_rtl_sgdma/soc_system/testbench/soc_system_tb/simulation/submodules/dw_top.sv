module dw_top (
    input  logic         clk,
    input  logic         rst_n,


    input  logic         mcp_valid,
    input  logic [2:0]   mcp_data,     

    output logic         dw_valid,
    output logic [11:0]  dw_data_out   
);

    logic        win_valid;
    logic [26:0] win_data; 

    window3x3s1 #(
        .DATA_WIDTH(3), 
        .IMG_WIDTH(15)     
    ) u_window (
        .clk         (clk),
        .rst_n       (rst_n),
        .din_valid   (mcp_valid),
        .din         (mcp_data),
        .dout_valid  (win_valid),
        .dout_window (win_data)
    );


    
    localparam logic [8:0] dw_weights [0:2] = '{
        9'h092,
        9'h01b,
        9'h007
    };


    logic [8:0] ch0_win, ch1_win, ch2_win;
    
    genvar i;
    generate

        for (i = 0; i < 9; i++) begin : gen_untangle
            assign ch0_win[i] = win_data[i*3 + 0];
            assign ch1_win[i] = win_data[i*3 + 1];
            assign ch2_win[i] = win_data[i*3 + 2];
        end
    endgenerate

    logic       valid_out_arr [0:2];
    logic [3:0] data_out_ch0, data_out_ch1, data_out_ch2;

    dw_pe pe_ch0 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (win_valid),
        .window_in (ch0_win),
        .weight_in (dw_weights[0]),
        .valid_out (valid_out_arr[0]),
        .data_out  (data_out_ch0)
    );

    dw_pe pe_ch1 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (win_valid),
        .window_in (ch1_win),
        .weight_in (dw_weights[1]),
        .valid_out (valid_out_arr[1]),
        .data_out  (data_out_ch1)
    );

    dw_pe pe_ch2 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (win_valid),
        .window_in (ch2_win),
        .weight_in (dw_weights[2]),
        .valid_out (valid_out_arr[2]),
        .data_out  (data_out_ch2)
    );

  
    
    assign dw_valid    = valid_out_arr[0];
    
    
    assign dw_data_out = {data_out_ch2, data_out_ch1, data_out_ch0};

endmodule