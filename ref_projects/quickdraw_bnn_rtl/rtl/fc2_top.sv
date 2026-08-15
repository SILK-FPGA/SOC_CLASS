module fc2_top (
    input  logic         clk,
    input  logic         rst_n,

    // Ngõ vào từ FC1
    input  logic         fc1_valid,
    input  logic [63:0]  fc1_data_in,

    // Ngõ ra kết quả cuối cùng
    output logic         fc2_valid,
    output logic [3:0]   class_out    // 10 class
  );




  localparam logic [63:0] fc2_weights [0:9] = '{
               64'h5540610418260043,
               64'h203079aa59180041,
               64'h04a728450065b430,
               64'h4601b011805033c2,
               64'h762a53b8c1134233,
               64'h32e083aaa00a4f13,
               64'h008400020cd10ca4,
               64'hb49b049027681090,
               64'ha440000f420ac000,
               64'h838c12b00c201038

             };


  localparam logic signed [31:0] lut_0 [0:64] = '{
               32'hfff81db9,
               32'hfff925cd,
               32'hfffa2de2,
               32'hfffb35f6,
               32'hfffc3e0b,
               32'hfffd461f,
               32'hfffe4e34,
               32'hffff5648,
               32'h00005e5d,
               32'h00016671,
               32'h00026e86,
               32'h0003769a,
               32'h00047eaf,
               32'h000586c3,
               32'h00068ed7,
               32'h000796ec,
               32'h00089f00,
               32'h0009a715,
               32'h000aaf29,
               32'h000bb73e,
               32'h000cbf52,
               32'h000dc767,
               32'h000ecf7b,
               32'h000fd790,
               32'h0010dfa4,
               32'h0011e7b9,
               32'h0012efcd,
               32'h0013f7e2,
               32'h0014fff6,
               32'h0016080b,
               32'h0017101f,
               32'h00181834,
               32'h00192048,
               32'h001a285d,
               32'h001b3071,
               32'h001c3885,
               32'h001d409a,
               32'h001e48ae,
               32'h001f50c3,
               32'h002058d7,
               32'h002160ec,
               32'h00226900,
               32'h00237115,
               32'h00247929,
               32'h0025813e,
               32'h00268952,
               32'h00279167,
               32'h0028997b,
               32'h0029a190,
               32'h002aa9a4,
               32'h002bb1b9,
               32'h002cb9cd,
               32'h002dc1e2,
               32'h002ec9f6,
               32'h002fd20b,
               32'h0030da1f,
               32'h0031e234,
               32'h0032ea48,
               32'h0033f25c,
               32'h0034fa71,
               32'h00360285,
               32'h00370a9a,
               32'h003812ae,
               32'h00391ac3,
               32'h003a22d7
             };

  localparam logic signed [31:0] lut_1 [0:64] = '{
               32'hfff78f89,
               32'hfff88e36,
               32'hfff98ce4,
               32'hfffa8b91,
               32'hfffb8a3e,
               32'hfffc88eb,
               32'hfffd8799,
               32'hfffe8646,
               32'hffff84f3,
               32'h000083a0,
               32'h0001824e,
               32'h000280fb,
               32'h00037fa8,
               32'h00047e56,
               32'h00057d03,
               32'h00067bb0,
               32'h00077a5d,
               32'h0008790b,
               32'h000977b8,
               32'h000a7665,
               32'h000b7512,
               32'h000c73c0,
               32'h000d726d,
               32'h000e711a,
               32'h000f6fc7,
               32'h00106e75,
               32'h00116d22,
               32'h00126bcf,
               32'h00136a7d,
               32'h0014692a,
               32'h001567d7,
               32'h00166684,
               32'h00176532,
               32'h001863df,
               32'h0019628c,
               32'h001a6139,
               32'h001b5fe7,
               32'h001c5e94,
               32'h001d5d41,
               32'h001e5bee,
               32'h001f5a9c,
               32'h00205949,
               32'h002157f6,
               32'h002256a4,
               32'h00235551,
               32'h002453fe,
               32'h002552ab,
               32'h00265159,
               32'h00275006,
               32'h00284eb3,
               32'h00294d60,
               32'h002a4c0e,
               32'h002b4abb,
               32'h002c4968,
               32'h002d4815,
               32'h002e46c3,
               32'h002f4570,
               32'h0030441d,
               32'h003142cb,
               32'h00324178,
               32'h00334025,
               32'h00343ed2,
               32'h00353d80,
               32'h00363c2d,
               32'h00373ada
             };

  localparam logic signed [31:0] lut_2 [0:64] = '{
               32'hfff82b92,
               32'hfff9081d,
               32'hfff9e4a8,
               32'hfffac133,
               32'hfffb9dbe,
               32'hfffc7a49,
               32'hfffd56d5,
               32'hfffe3360,
               32'hffff0feb,
               32'hffffec76,
               32'h0000c901,
               32'h0001a58c,
               32'h00028218,
               32'h00035ea3,
               32'h00043b2e,
               32'h000517b9,
               32'h0005f444,
               32'h0006d0d0,
               32'h0007ad5b,
               32'h000889e6,
               32'h00096671,
               32'h000a42fc,
               32'h000b1f87,
               32'h000bfc13,
               32'h000cd89e,
               32'h000db529,
               32'h000e91b4,
               32'h000f6e3f,
               32'h00104acb,
               32'h00112756,
               32'h001203e1,
               32'h0012e06c,
               32'h0013bcf7,
               32'h00149982,
               32'h0015760e,
               32'h00165299,
               32'h00172f24,
               32'h00180baf,
               32'h0018e83a,
               32'h0019c4c5,
               32'h001aa151,
               32'h001b7ddc,
               32'h001c5a67,
               32'h001d36f2,
               32'h001e137d,
               32'h001ef009,
               32'h001fcc94,
               32'h0020a91f,
               32'h002185aa,
               32'h00226235,
               32'h00233ec0,
               32'h00241b4c,
               32'h0024f7d7,
               32'h0025d462,
               32'h0026b0ed,
               32'h00278d78,
               32'h00286a03,
               32'h0029468f,
               32'h002a231a,
               32'h002affa5,
               32'h002bdc30,
               32'h002cb8bb,
               32'h002d9547,
               32'h002e71d2,
               32'h002f4e5d
             };

  localparam logic signed [31:0] lut_3 [0:64] = '{
               32'hfff6e7c9,
               32'hfff7eef1,
               32'hfff8f619,
               32'hfff9fd42,
               32'hfffb046a,
               32'hfffc0b92,
               32'hfffd12ba,
               32'hfffe19e2,
               32'hffff210a,
               32'h00002832,
               32'h00012f5a,
               32'h00023682,
               32'h00033daa,
               32'h000444d2,
               32'h00054bfa,
               32'h00065322,
               32'h00075a4a,
               32'h00086172,
               32'h0009689a,
               32'h000a6fc3,
               32'h000b76eb,
               32'h000c7e13,
               32'h000d853b,
               32'h000e8c63,
               32'h000f938b,
               32'h00109ab3,
               32'h0011a1db,
               32'h0012a903,
               32'h0013b02b,
               32'h0014b753,
               32'h0015be7b,
               32'h0016c5a3,
               32'h0017cccb,
               32'h0018d3f3,
               32'h0019db1b,
               32'h001ae244,
               32'h001be96c,
               32'h001cf094,
               32'h001df7bc,
               32'h001efee4,
               32'h0020060c,
               32'h00210d34,
               32'h0022145c,
               32'h00231b84,
               32'h002422ac,
               32'h002529d4,
               32'h002630fc,
               32'h00273824,
               32'h00283f4c,
               32'h00294674,
               32'h002a4d9c,
               32'h002b54c5,
               32'h002c5bed,
               32'h002d6315,
               32'h002e6a3d,
               32'h002f7165,
               32'h0030788d,
               32'h00317fb5,
               32'h003286dd,
               32'h00338e05,
               32'h0034952d,
               32'h00359c55,
               32'h0036a37d,
               32'h0037aaa5,
               32'h0038b1cd
             };

  localparam logic signed [31:0] lut_4 [0:64] = '{
               32'hfff78b2d,
               32'hfff8545b,
               32'hfff91d8a,
               32'hfff9e6b8,
               32'hfffaafe7,
               32'hfffb7915,
               32'hfffc4243,
               32'hfffd0b72,
               32'hfffdd4a0,
               32'hfffe9dcf,
               32'hffff66fd,
               32'h0000302c,
               32'h0000f95a,
               32'h0001c289,
               32'h00028bb7,
               32'h000354e5,
               32'h00041e14,
               32'h0004e742,
               32'h0005b071,
               32'h0006799f,
               32'h000742ce,
               32'h00080bfc,
               32'h0008d52b,
               32'h00099e59,
               32'h000a6787,
               32'h000b30b6,
               32'h000bf9e4,
               32'h000cc313,
               32'h000d8c41,
               32'h000e5570,
               32'h000f1e9e,
               32'h000fe7cd,
               32'h0010b0fb,
               32'h00117a29,
               32'h00124358,
               32'h00130c86,
               32'h0013d5b5,
               32'h00149ee3,
               32'h00156812,
               32'h00163140,
               32'h0016fa6f,
               32'h0017c39d,
               32'h00188ccc,
               32'h001955fa,
               32'h001a1f28,
               32'h001ae857,
               32'h001bb185,
               32'h001c7ab4,
               32'h001d43e2,
               32'h001e0d11,
               32'h001ed63f,
               32'h001f9f6e,
               32'h0020689c,
               32'h002131ca,
               32'h0021faf9,
               32'h0022c427,
               32'h00238d56,
               32'h00245684,
               32'h00251fb3,
               32'h0025e8e1,
               32'h0026b210,
               32'h00277b3e,
               32'h0028446c,
               32'h00290d9b,
               32'h0029d6c9
             };

  localparam logic signed [31:0] lut_5 [0:64] = '{
               32'hfffa280a,
               32'hfffaeb3b,
               32'hfffbae6c,
               32'hfffc719d,
               32'hfffd34ce,
               32'hfffdf7ff,
               32'hfffebb30,
               32'hffff7e60,
               32'h00004191,
               32'h000104c2,
               32'h0001c7f3,
               32'h00028b24,
               32'h00034e55,
               32'h00041186,
               32'h0004d4b7,
               32'h000597e7,
               32'h00065b18,
               32'h00071e49,
               32'h0007e17a,
               32'h0008a4ab,
               32'h000967dc,
               32'h000a2b0d,
               32'h000aee3d,
               32'h000bb16e,
               32'h000c749f,
               32'h000d37d0,
               32'h000dfb01,
               32'h000ebe32,
               32'h000f8163,
               32'h00104493,
               32'h001107c4,
               32'h0011caf5,
               32'h00128e26,
               32'h00135157,
               32'h00141488,
               32'h0014d7b9,
               32'h00159aea,
               32'h00165e1a,
               32'h0017214b,
               32'h0017e47c,
               32'h0018a7ad,
               32'h00196ade,
               32'h001a2e0f,
               32'h001af140,
               32'h001bb470,
               32'h001c77a1,
               32'h001d3ad2,
               32'h001dfe03,
               32'h001ec134,
               32'h001f8465,
               32'h00204796,
               32'h00210ac7,
               32'h0021cdf7,
               32'h00229128,
               32'h00235459,
               32'h0024178a,
               32'h0024dabb,
               32'h00259dec,
               32'h0026611d,
               32'h0027244d,
               32'h0027e77e,
               32'h0028aaaf,
               32'h00296de0,
               32'h002a3111,
               32'h002af442
             };

  localparam logic signed [31:0] lut_6 [0:64] = '{
               32'hfffa1e90,
               32'hfffb1805,
               32'hfffc117a,
               32'hfffd0aef,
               32'hfffe0465,
               32'hfffefdda,
               32'hfffff74f,
               32'h0000f0c4,
               32'h0001ea39,
               32'h0002e3ae,
               32'h0003dd24,
               32'h0004d699,
               32'h0005d00e,
               32'h0006c983,
               32'h0007c2f8,
               32'h0008bc6d,
               32'h0009b5e3,
               32'h000aaf58,
               32'h000ba8cd,
               32'h000ca242,
               32'h000d9bb7,
               32'h000e952c,
               32'h000f8ea1,
               32'h00108817,
               32'h0011818c,
               32'h00127b01,
               32'h00137476,
               32'h00146deb,
               32'h00156760,
               32'h001660d6,
               32'h00175a4b,
               32'h001853c0,
               32'h00194d35,
               32'h001a46aa,
               32'h001b401f,
               32'h001c3995,
               32'h001d330a,
               32'h001e2c7f,
               32'h001f25f4,
               32'h00201f69,
               32'h002118de,
               32'h00221254,
               32'h00230bc9,
               32'h0024053e,
               32'h0024feb3,
               32'h0025f828,
               32'h0026f19d,
               32'h0027eb13,
               32'h0028e488,
               32'h0029ddfd,
               32'h002ad772,
               32'h002bd0e7,
               32'h002cca5c,
               32'h002dc3d2,
               32'h002ebd47,
               32'h002fb6bc,
               32'h0030b031,
               32'h0031a9a6,
               32'h0032a31b,
               32'h00339c91,
               32'h00349606,
               32'h00358f7b,
               32'h003688f0,
               32'h00378265,
               32'h00387bda
             };

  localparam logic signed [31:0] lut_7 [0:64] = '{
               32'hfff7d92b,
               32'hfff8c5dd,
               32'hfff9b28f,
               32'hfffa9f42,
               32'hfffb8bf4,
               32'hfffc78a6,
               32'hfffd6558,
               32'hfffe520b,
               32'hffff3ebd,
               32'h00002b6f,
               32'h00011821,
               32'h000204d4,
               32'h0002f186,
               32'h0003de38,
               32'h0004caea,
               32'h0005b79d,
               32'h0006a44f,
               32'h00079101,
               32'h00087db3,
               32'h00096a66,
               32'h000a5718,
               32'h000b43ca,
               32'h000c307c,
               32'h000d1d2e,
               32'h000e09e1,
               32'h000ef693,
               32'h000fe345,
               32'h0010cff7,
               32'h0011bcaa,
               32'h0012a95c,
               32'h0013960e,
               32'h001482c0,
               32'h00156f73,
               32'h00165c25,
               32'h001748d7,
               32'h00183589,
               32'h0019223c,
               32'h001a0eee,
               32'h001afba0,
               32'h001be852,
               32'h001cd505,
               32'h001dc1b7,
               32'h001eae69,
               32'h001f9b1b,
               32'h002087ce,
               32'h00217480,
               32'h00226132,
               32'h00234de4,
               32'h00243a97,
               32'h00252749,
               32'h002613fb,
               32'h002700ad,
               32'h0027ed60,
               32'h0028da12,
               32'h0029c6c4,
               32'h002ab376,
               32'h002ba028,
               32'h002c8cdb,
               32'h002d798d,
               32'h002e663f,
               32'h002f52f1,
               32'h00303fa4,
               32'h00312c56,
               32'h00321908,
               32'h003305ba
             };

  localparam logic signed [31:0] lut_8 [0:64] = '{
               32'hfff8752d,
               32'hfff98ea3,
               32'hfffaa819,
               32'hfffbc18f,
               32'hfffcdb05,
               32'hfffdf47c,
               32'hffff0df2,
               32'h00002768,
               32'h000140de,
               32'h00025a54,
               32'h000373cb,
               32'h00048d41,
               32'h0005a6b7,
               32'h0006c02d,
               32'h0007d9a3,
               32'h0008f319,
               32'h000a0c90,
               32'h000b2606,
               32'h000c3f7c,
               32'h000d58f2,
               32'h000e7268,
               32'h000f8bdf,
               32'h0010a555,
               32'h0011becb,
               32'h0012d841,
               32'h0013f1b7,
               32'h00150b2d,
               32'h001624a4,
               32'h00173e1a,
               32'h00185790,
               32'h00197106,
               32'h001a8a7c,
               32'h001ba3f3,
               32'h001cbd69,
               32'h001dd6df,
               32'h001ef055,
               32'h002009cb,
               32'h00212341,
               32'h00223cb8,
               32'h0023562e,
               32'h00246fa4,
               32'h0025891a,
               32'h0026a290,
               32'h0027bc07,
               32'h0028d57d,
               32'h0029eef3,
               32'h002b0869,
               32'h002c21df,
               32'h002d3b55,
               32'h002e54cc,
               32'h002f6e42,
               32'h003087b8,
               32'h0031a12e,
               32'h0032baa4,
               32'h0033d41b,
               32'h0034ed91,
               32'h00360707,
               32'h0037207d,
               32'h003839f3,
               32'h00395369,
               32'h003a6ce0,
               32'h003b8656,
               32'h003c9fcc,
               32'h003db942,
               32'h003ed2b8
             };

  localparam logic signed [31:0] lut_9 [0:64] = '{
               32'hfffae403,
               32'hfffbb48a,
               32'hfffc8512,
               32'hfffd5599,
               32'hfffe2620,
               32'hfffef6a8,
               32'hffffc72f,
               32'h000097b7,
               32'h0001683e,
               32'h000238c5,
               32'h0003094d,
               32'h0003d9d4,
               32'h0004aa5c,
               32'h00057ae3,
               32'h00064b6b,
               32'h00071bf2,
               32'h0007ec79,
               32'h0008bd01,
               32'h00098d88,
               32'h000a5e10,
               32'h000b2e97,
               32'h000bff1e,
               32'h000ccfa6,
               32'h000da02d,
               32'h000e70b5,
               32'h000f413c,
               32'h001011c4,
               32'h0010e24b,
               32'h0011b2d2,
               32'h0012835a,
               32'h001353e1,
               32'h00142469,
               32'h0014f4f0,
               32'h0015c578,
               32'h001695ff,
               32'h00176686,
               32'h0018370e,
               32'h00190795,
               32'h0019d81d,
               32'h001aa8a4,
               32'h001b792b,
               32'h001c49b3,
               32'h001d1a3a,
               32'h001deac2,
               32'h001ebb49,
               32'h001f8bd1,
               32'h00205c58,
               32'h00212cdf,
               32'h0021fd67,
               32'h0022cdee,
               32'h00239e76,
               32'h00246efd,
               32'h00253f84,
               32'h0026100c,
               32'h0026e093,
               32'h0027b11b,
               32'h002881a2,
               32'h0029522a,
               32'h002a22b1,
               32'h002af338,
               32'h002bc3c0,
               32'h002c9447,
               32'h002d64cf,
               32'h002e3556,
               32'h002f05dd
             };


  // ==========================================
  // MẠCH TỔ HỢP: NHÂN TRỌNG SỐ VÀ ĐẾM POPCOUNT
  // ==========================================
  logic [63:0] and_res  [0:9];
  logic [6:0]  pop_comb [0:9]; // 64 bit cần 7 bit đếm (giá trị từ 0 đến 64)

  // Dùng khối generate để tạo song song 10 phép AND và 10 khối Popcount 64-bit
  genvar i;
  generate
    for (i = 0; i < 10; i++)
    begin : gen_fc2_mac
      assign and_res[i] = fc1_data_in & fc2_weights[i];
      popcount #(64) pc (.data_in(and_res[i]), .count_out(pop_comb[i]));
    end
  endgenerate

  // ==========================================
  // PIPELINE TẦNG 1: CHỐT KẾT QUẢ POPCOUNT
  // ==========================================
  logic [6:0] pop [0:9];
  logic       valid_stg1;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      for (int j = 0; j < 10; j++)
        pop[j] <= '0;
      valid_stg1 <= 1'b0;
    end
    else
    begin
      valid_stg1 <= fc1_valid;
      if (fc1_valid)
      begin
        for (int j = 0; j < 10; j++)
          pop[j] <= pop_comb[j];
      end
    end
  end

  // ==========================================
  // PIPELINE TẦNG 2: TRA CỨU ĐIỂM SỐ (LUT LOOKUP)
  // ==========================================
  logic signed [31:0] score [0:9];
  logic               valid_stg2;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      for (int j = 0; j < 10; j++)
        score[j] <= '0;
      valid_stg2 <= 1'b0;
    end
    else
    begin
      valid_stg2 <= valid_stg1;
      if (valid_stg1)
      begin
        // Lấy giá trị popcount làm địa chỉ móc dữ liệu từ ROM
        // Viết tường minh để Quartus map chính xác vào 10 bảng LUT tĩnh
        score[0] <= lut_0[pop[0]];
        score[1] <= lut_1[pop[1]];
        score[2] <= lut_2[pop[2]];
        score[3] <= lut_3[pop[3]];
        score[4] <= lut_4[pop[4]];
        score[5] <= lut_5[pop[5]];
        score[6] <= lut_6[pop[6]];
        score[7] <= lut_7[pop[7]];
        score[8] <= lut_8[pop[8]];
        score[9] <= lut_9[pop[9]];
      end
    end
  end

  logic signed [31:0] t1_val [0:4];
  logic [3:0]         t1_idx [0:4];
  logic               valid_t1;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      for(int k=0; k<5; k++)
      begin
        t1_val[k] <= '0;
        t1_idx[k] <= '0;
      end
      valid_t1 <= 1'b0;
    end
    else
    begin
      valid_t1 <= valid_stg2;
      if (valid_stg2)
      begin
        for (int k=0; k<5; k++)
        begin
          if (score[2*k] >= score[2*k+1])
          begin
            t1_val[k] <= score[2*k];
            t1_idx[k] <= 4'(2*k);
          end
          else
          begin
            t1_val[k] <= score[2*k+1];
            t1_idx[k] <= 4'(2*k+1);
          end
        end
      end
    end
  end

  logic signed [31:0] t2_val [0:2];
  logic [3:0]         t2_idx [0:2];
  logic               valid_t2;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      for(int k=0; k<3; k++)
      begin
        t2_val[k] <= '0;
        t2_idx[k] <= '0;
      end
      valid_t2 <= 1'b0;
    end
    else
    begin
      valid_t2 <= valid_t1;
      if (valid_t1)
      begin
        // Cặp 1
        if (t1_val[0] >= t1_val[1])
        begin
          t2_val[0] <= t1_val[0];
          t2_idx[0] <= t1_idx[0];
        end
        else
        begin
          t2_val[0] <= t1_val[1];
          t2_idx[0] <= t1_idx[1];
        end
        // Cặp 2
        if (t1_val[2] >= t1_val[3])
        begin
          t2_val[1] <= t1_val[2];
          t2_idx[1] <= t1_idx[2];
        end
        else
        begin
          t2_val[1] <= t1_val[3];
          t2_idx[1] <= t1_idx[3];
        end
        // Nhánh lẻ
        t2_val[2] <= t1_val[4];
        t2_idx[2] <= t1_idx[4];
      end
    end
  end

  logic signed [31:0] t3_val [0:1];
  logic [3:0]         t3_idx [0:1];
  logic               valid_t3;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      for(int k=0; k<2; k++)
      begin
        t3_val[k] <= '0;
        t3_idx[k] <= '0;
      end
      valid_t3 <= 1'b0;
    end
    else
    begin
      valid_t3 <= valid_t2;
      if (valid_t2)
      begin
        if (t2_val[0] >= t2_val[1])
        begin
          t3_val[0] <= t2_val[0];
          t3_idx[0] <= t2_idx[0];
        end
        else
        begin
          t3_val[0] <= t2_val[1];
          t3_idx[0] <= t2_idx[1];
        end

        t3_val[1] <= t2_val[2];
        t3_idx[1] <= t2_idx[2];
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      class_out <= '0;
      fc2_valid <= 1'b0;
    end
    else
    begin
      fc2_valid <= valid_t3;
      if (valid_t3)
      begin
        if (t3_val[0] >= t3_val[1])
          class_out <= t3_idx[0];
        else
          class_out <= t3_idx[1];
      end
    end
  end


endmodule
