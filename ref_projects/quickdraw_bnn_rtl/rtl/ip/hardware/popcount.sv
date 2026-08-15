module popcount 
#(
    parameter int INPUT_WIDTH = 9
)
(
   input  logic [INPUT_WIDTH-1:0]           data_in,
   output logic [$clog2(INPUT_WIDTH+1)-1:0] count_out 
);

    logic [$clog2(INPUT_WIDTH+1)-1:0] temp_sum;
    integer i;

    always_comb begin
        temp_sum = '0; // Khởi tạo tổng bằng 0
        // Vòng lặp đếm qua tất cả các bit của bó cáp đầu vào
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            temp_sum = temp_sum + data_in[i];
        end
        count_out = temp_sum;
    end

endmodule