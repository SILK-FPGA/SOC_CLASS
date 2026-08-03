module avalon_sdr (
    // clk and reset are always required.
    input   logic         clk,
    input   logic         reset,
    // Bidirectional ports i.e. read and write.
    output  logic         avm_m0_read,   // doc tu ram
    //output  logic         avm_m0_write, // ghi vo ram
    //output  logic [255:0] avm_m0_writedata, // gia tri ghi vo
    output  logic [31:0]  avm_m0_address,   // dia chi bat dau
    input   logic [31:0]  avm_m0_readdata,  // gia tri doc tu ram
    input   logic         avm_m0_readdatavalid, // co gia tri doc
    output  logic [31:0]  avm_m0_byteenable,  // mat na byte chi dung cho ghi
    input   logic         avm_m0_waitrequest, // co san sang
    output  logic [10:0]  avm_m0_burstcount,  // so goi trong 1 giao dich
    // External.
    input   logic         do_read,
    input   logic [19:0]  init_addr,
    input   logic [10:0]  burst_length,
    output  logic [31:0] out_data_1,
    output  logic [31:0] out_data_2
  );

  localparam INIT = 2'd0;
  localparam READ_START = 2'd1;
  localparam READ_PROC = 2'd2;


  logic [10:0] burst_count, n_burst_count;
  logic [1:0] cur_state;
  logic [1:0] next_state;
  /// ff update
  always_ff @(posedge clk)
  begin
    if (reset)
    begin
      cur_state <= INIT;
      burst_count <= 'd0;
    end
    else
    begin
      cur_state <= next_state;
      burst_count <= n_burst_count;
    end
  end

  /// state transition logic
  always_comb
  begin
    next_state = cur_state;
    case(cur_state)
      INIT:
      begin
        if (do_read)
          next_state = READ_START;
      end

      READ_START:
      begin
        if (avm_m0_waitrequest)
          next_state = READ_START; // Wait here.
        else
          next_state = READ_PROC;
      end

      READ_PROC:
      begin
        if (|burst_count)
          next_state = READ_PROC; // Wait here.
        else
          next_state = INIT;
      end

      default:
      begin
        next_state = INIT;
      end
    endcase
  end

  /// output logic
  always_comb
  begin
    avm_m0_address = 32'd0;
    avm_m0_read = 1'b0;
    avm_m0_byteenable = 32'd0;
    avm_m0_burstcount = 11'd0;
    n_burst_count = burst_length;
    case(cur_state)

      READ_START:
      begin
        avm_m0_address = {init_addr,12'd0};
        avm_m0_read = 1'b1;
        avm_m0_byteenable = 32'h0000_000F; // Get 32 bits only.
        avm_m0_burstcount = burst_length; // gia tri goi trong 1 giao dich
      end
      READ_PROC:
      begin
        if (avm_m0_readdatavalid)
          n_burst_count = burst_count - 1;
      end

      default:
      begin
      end
    endcase
  end
  /// output logic
  always_ff @(posedge clk)
  begin
    if (reset)
    begin
      out_data_1 <= 'd0;
      out_data_2 <= 'd0;
    end
    else
    begin
      case (cur_state)
        READ_PROC:
        begin
          if (avm_m0_readdatavalid)
          begin
            if (burst_count[0])
              out_data_1 <= avm_m0_readdata; //le
            else
              out_data_2 <= avm_m0_readdata; //chan
          end
        end

        default:
        begin
        end
      endcase
    end
  end

endmodule
