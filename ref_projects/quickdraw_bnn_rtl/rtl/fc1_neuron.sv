module fc1_neuron (
    input  logic             clk,
    input  logic             rst_n,

    input  logic             valid_in,
    input  logic [3045:0]    data_in,    // Vector đầu vào (Feature Map + RR)
    input  logic [3045:0]    weight_in,  // 1 dòng trọng số từ fc1_weights.hex
    input  logic [16:0]      thresh_in,  // Ngưỡng của Neuron này

    output logic             valid_out,
    output logic             data_out    // 1 bit nhị phân kết quả
  );


  logic polarity;
  logic signed [15:0] thresh_value;

  logic [16:0] thresh1, thresh2;
  logic valid1, valid2;

  logic [3045:0] and_res;

  always_ff @(posedge clk or negedge rst_n )
  begin
    if (!rst_n)
    begin
      thresh1 <= '0;
      valid1 <= '0;
      and_res <= '0;
    end
    else
    begin
      valid1  <= valid_in; //nêu bỏ trong if (valid_in) thì khi valid_in = 0, valid1 sẽ bằng 1 quài 
      if (valid_in)
      begin
        thresh1 <= thresh_in;
        and_res <= weight_in & data_in;
      end
    end
  end

  logic [11:0] sum_out_res;
  logic [9:0] chunk_out1,chunk_out2,chunk_out3,chunk_out4;
  logic signed [12:0] sum_out_signed;
  
  popcount # (762)
           popcount1
           (
             .data_in(and_res[761:0]),
             .count_out(chunk_out1)
           );

  popcount # (762)
           popcount2
           (
             .data_in(and_res[1523:762]),
             .count_out(chunk_out2)
           ); 
  popcount # (762)
           popcount3
           (
             .data_in(and_res[2285:1524]),
             .count_out(chunk_out3)
           );
  popcount # (760)
           popcount4
           (
             .data_in(and_res[3045:2286]),
             .count_out(chunk_out4)
           );     

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      sum_out_res  <= '0;
      valid2 <= '0;
      thresh2 <= '0;
    end
    else
    begin
      // Trượt cờ Valid qua tầng thứ 2, tính popcount
      valid2 <= valid1;

      if (valid1)
      begin
        // Đếm tổng số bit 1
        sum_out_res <= chunk_out1 + chunk_out2 + chunk_out3 + chunk_out4;
        thresh2 <= thresh1;
      end
    end
  end
  // những gì diễn ra tại trước cạnh lên chu kì kế tiếp
  assign sum_out_signed = {1'b0,sum_out_res}; // có dấu
  assign polarity = thresh2[16];
  assign thresh_value = thresh2[15:0];
  logic data_out_t;
  assign data_out_t = (polarity) ? ((sum_out_signed >= thresh_value) ? 1 : 0) : ((sum_out_signed <= thresh_value) ? 1 : 0);
  
  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out  <= '0;
      valid_out <= '0;
    end
    else
    begin
      valid_out <= valid2;
      if (valid2)
      
        
        data_out <= data_out_t;
    
    end
  end
endmodule
