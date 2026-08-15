module window3x3s1 // tạo cửa sổ 3x3 với bước trượt s = 1
  #(
     parameter int DATA_WIDTH = 8, // kích thước 1 pixel
     parameter int IMG_WIDTH  = 4  // chiều rộng ảnh đầu vào 4x4 =16
   )
   (
     input  logic                    clk,
     input  logic                    rst_n,
     input  logic                    din_valid,
     input  logic [DATA_WIDTH-1:0]   din,

     output logic                    dout_valid,
     output logic [9*DATA_WIDTH-1:0] dout_window  // trải thành mảng 1D
   );


  logic [$clog2(IMG_WIDTH)-1:0] col_index;
  logic [$clog2(IMG_WIDTH)-1:0] row_index;


  logic [DATA_WIDTH-1:0] buff_row1 [0:IMG_WIDTH-1];
  logic [DATA_WIDTH-1:0] buff_row2 [0:IMG_WIDTH-1];


  logic [DATA_WIDTH-1:0] temp [0:8];


  assign dout_window = {temp[8], temp[7], temp[6], temp[5], temp[4], temp[3], temp[2], temp[1], temp[0]};


  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      col_index  <= '0;
      row_index  <= '0;
      dout_valid <= 1'b0;

      for (int i = 0; i < IMG_WIDTH; i++)
      begin
        buff_row1[i] <= '0;
        buff_row2[i] <= '0;
      end

      for (int i = 0; i < 9; i++)
      
        temp[i] <= '0;
    end
    else if (din_valid)
    begin
      for (int i = 1; i < IMG_WIDTH; i++)
      begin
        buff_row1[i] <= buff_row1[i-1];
        buff_row2[i] <= buff_row2[i-1];
      end


      buff_row1[0] <= din;
      buff_row2[0] <= buff_row1[IMG_WIDTH-1];


      temp[8] <= din;
      temp[7] <= temp[8];
      temp[6] <= temp[7];


      temp[5] <= buff_row1[IMG_WIDTH-1];
      temp[4] <= temp[5];
      temp[3] <= temp[4];

      temp[2] <= buff_row2[IMG_WIDTH-1];
      temp[1] <= temp[2];
      temp[0] <= temp[1];


      if (col_index == IMG_WIDTH - 1)
      begin
        col_index <= '0;
        if (row_index == IMG_WIDTH - 1) 
          row_index <= '0;
        else 
          row_index <= row_index + 1;
      end
      else 
          col_index <= col_index + 1;

      if (row_index >= 2 && col_index >= 2)
          dout_valid <= 1'b1;
      else
          dout_valid <= 1'b0;
    end
    else
          dout_valid <= 1'b0;
  end

endmodule
