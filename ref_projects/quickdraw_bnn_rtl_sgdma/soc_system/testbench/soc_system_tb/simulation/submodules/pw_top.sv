module pw_top (
    input  logic         clk,
    input  logic         rst_n,

    // Ngõ vào từ lớp DW (12-bit chứa 3 số nguyên)
    input  logic         dw_valid,
    input  logic [11:0]  dw_data,

    // Ngõ ra tới lớp FC1
    output logic         pw_valid,
    output logic [17:0]  pw_data_out
);

  

    
    localparam logic [2:0] pw_weights [0:17] = '{
    3'h1,
    3'h1,
    3'h1,
    3'h1,
    3'h0,
    3'h0,
    3'h6,
    3'h4,
    3'h7,
    3'h5,
    3'h1,
    3'h3,
    3'h6,
    3'h4,
    3'h4,
    3'h0,
    3'h4,
    3'h3

};
    localparam logic [16:0] pw_thresh [0:17] = '{
    17'h10001,
    17'h10001,
    17'h10001,
    17'h10001,
    17'h10001,
    17'h10000,
    17'h10006,
    17'h10001,
    17'h10005,
    17'h10005,
    17'h10001,
    17'h10003,
    17'h10005,
    17'h10001,
    17'h10001,
    17'h10000,
    17'h10001,
    17'h10005

};
    logic [17:0] valid_out_arr;

    genvar i;
    generate
        for (i = 0; i < 18; i++) begin : gen_pw_neurons
            pw_pe u_pe (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (dw_valid),
                

                .dw_out_0  (dw_data[3:0]),
                .dw_out_1  (dw_data[7:4]),
                .dw_out_2  (dw_data[11:8]),
                
                .weight_in (pw_weights[i]),
                .thresh_in (pw_thresh[i]),
                .valid_out (valid_out_arr[i]),
                .data_out  (pw_data_out[i])
            );
        end
    endgenerate

    assign pw_valid = valid_out_arr[0];

endmodule