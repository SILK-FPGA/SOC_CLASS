
module DE10_NANO(

    //////////// CLOCK //////////
    input                       FPGA_CLK1_50,
    input                       FPGA_CLK2_50,
    input                       FPGA_CLK3_50,

    //////////// HDMI //////////
    inout                       HDMI_I2C_SCL,
    inout                       HDMI_I2C_SDA,
    inout                       HDMI_I2S,
    inout                       HDMI_LRCLK,
    inout                       HDMI_MCLK,
    inout                       HDMI_SCLK,

    output                      HDMI_TX_CLK,
    output                      HDMI_TX_DE,
    output          [23:0]      HDMI_TX_D,
    output                      HDMI_TX_HS,
    input                       HDMI_TX_INT,
    output                      HDMI_TX_VS,

    //////////// HPS //////////
    inout                       HPS_CONV_USB_N,

    output          [14:0]      HPS_DDR3_ADDR,
    output           [2:0]      HPS_DDR3_BA,
    output                      HPS_DDR3_CAS_N,
    output                      HPS_DDR3_CKE,
    output                      HPS_DDR3_CK_N,
    output                      HPS_DDR3_CK_P,
    output                      HPS_DDR3_CS_N,
    output           [3:0]      HPS_DDR3_DM,
    inout           [31:0]      HPS_DDR3_DQ,
    inout            [3:0]      HPS_DDR3_DQS_N,
    inout            [3:0]      HPS_DDR3_DQS_P,
    output                      HPS_DDR3_ODT,
    output                      HPS_DDR3_RAS_N,
    output                      HPS_DDR3_RESET_N,
    input                       HPS_DDR3_RZQ,
    output                      HPS_DDR3_WE_N,

    output                      HPS_ENET_GTX_CLK,
    inout                       HPS_ENET_INT_N,
    output                      HPS_ENET_MDC,
    inout                       HPS_ENET_MDIO,
    input                       HPS_ENET_RX_CLK,
    input            [3:0]      HPS_ENET_RX_DATA,
    input                       HPS_ENET_RX_DV,
    output           [3:0]      HPS_ENET_TX_DATA,
    output                      HPS_ENET_TX_EN,

    inout                       HPS_GSENSOR_INT,

    inout                       HPS_I2C0_SCLK,
    inout                       HPS_I2C0_SDAT,
    inout                       HPS_I2C1_SCLK,
    inout                       HPS_I2C1_SDAT,

    inout                       HPS_KEY,
    inout                       HPS_LED,
    inout                       HPS_LTC_GPIO,

    output                      HPS_SD_CLK,
    inout                       HPS_SD_CMD,
    inout            [3:0]      HPS_SD_DATA,

    output                      HPS_SPIM_CLK,
    input                       HPS_SPIM_MISO,
    output                      HPS_SPIM_MOSI,
    inout                       HPS_SPIM_SS,

    input                       HPS_UART_RX,
    output                      HPS_UART_TX,

    input                       HPS_USB_CLKOUT,
    inout            [7:0]      HPS_USB_DATA,
    input                       HPS_USB_DIR,
    input                       HPS_USB_NXT,
    output                      HPS_USB_STP,

    //////////// KEY //////////
    input            [1:0]      KEY,

    //////////// LED //////////
    output           [7:0]      LED,

    //////////// SW //////////
    input            [3:0]      SW,

    //////////// GPIO //////////
    inout           [35:0]      GPIO_0
);


//=======================================================
// CLOCK
//=======================================================

wire clock50;

assign clock50 = FPGA_CLK1_50;


//=======================================================
// HPS / QSYS SIGNALS
//=======================================================

wire hps_fpga_reset_n;


//=======================================================
// VIDEO DMA -> DUAL CLOCK FIFO OUTPUT
//
//=======================================================

wire        pixel_out_ready;
wire [7:0]  pixel_out_data;
wire        pixel_out_startofpacket;
wire        pixel_out_endofpacket;
wire        pixel_out_valid;


//=======================================================
// GRAYSCALE -> RGB888
//=======================================================

wire [23:0] hdmi_gray_rgb;

assign hdmi_gray_rgb = {
    hdmi_pixel,
    hdmi_pixel,
    hdmi_pixel
};


//=======================================================
// HDMI SIGNALS
//=======================================================

wire hdmi_pix_clk;
wire hdmi_pll_locked;

wire hdmi_config_ready;

wire        hdmi_hsync;
wire        hdmi_vsync;
wire        hdmi_de;

wire [10:0] hdmi_x;
wire [9:0]  hdmi_y;


//=======================================================
// VIDEO RESET REQUESTS
//=======================================================

wire video_dma_reset_req;
wire video_out_reset_req;



assign video_dma_reset_req = SW[1];




assign video_out_reset_req =
    SW[1] | ~hdmi_pll_locked;


//=======================================================
// SOC SYSTEM
//=======================================================

soc_system u_soc (

    //===================================================
    // MAIN QSYS CLOCK
    //===================================================

    .clk_clk (
        clock50
    ),


    //===================================================
    // HPS -> FPGA RESET
    //===================================================

    .reset_reset_n (
        hps_fpga_reset_n
    ),

    .hps_0_h2f_reset_reset_n (
        hps_fpga_reset_n
    ),


    .reset_bridge_0_in_reset_reset (
        video_dma_reset_req
    ),


    //===================================================
    // FIFO READ-SIDE CLOCK
    //===================================================

    .video_clk_clk (
        hdmi_pix_clk
    ),


    //===================================================
    // FIFO READ-SIDE RESET
    //===================================================

    .video_out_reset_reset (
        video_out_reset_req
    ),


    //===================================================
    // DUAL CLOCK FIFO OUTPUT
    //===================================================

    .pixel_out_ready (
        pixel_out_ready
    ),

    .pixel_out_data (
        pixel_out_data
    ),

    .pixel_out_startofpacket (
        pixel_out_startofpacket
    ),

    .pixel_out_endofpacket (
        pixel_out_endofpacket
    ),

    .pixel_out_valid (
        pixel_out_valid
    ),


    //===================================================
    // HPS DDR3
    //===================================================

    .memory_mem_a (
        HPS_DDR3_ADDR
    ),

    .memory_mem_ba (
        HPS_DDR3_BA
    ),

    .memory_mem_ck (
        HPS_DDR3_CK_P
    ),

    .memory_mem_ck_n (
        HPS_DDR3_CK_N
    ),

    .memory_mem_cke (
        HPS_DDR3_CKE
    ),

    .memory_mem_cs_n (
        HPS_DDR3_CS_N
    ),

    .memory_mem_ras_n (
        HPS_DDR3_RAS_N
    ),

    .memory_mem_cas_n (
        HPS_DDR3_CAS_N
    ),

    .memory_mem_we_n (
        HPS_DDR3_WE_N
    ),

    .memory_mem_reset_n (
        HPS_DDR3_RESET_N
    ),

    .memory_mem_dq (
        HPS_DDR3_DQ
    ),

    .memory_mem_dqs (
        HPS_DDR3_DQS_P
    ),

    .memory_mem_dqs_n (
        HPS_DDR3_DQS_N
    ),

    .memory_mem_odt (
        HPS_DDR3_ODT
    ),

    .memory_mem_dm (
        HPS_DDR3_DM
    ),

    .memory_oct_rzqin (
        HPS_DDR3_RZQ
    )
);


//=======================================================
// HDMI PIXEL CLOCK PLL
//=======================================================

pll_25Mhz u_pll_25 (

    .refclk (
        FPGA_CLK1_50
    ),

    // Active-high PLL reset
    .rst (
        !SW[0]
    ),

    .outclk_0 (
        hdmi_pix_clk
    ),

    .locked (
        hdmi_pll_locked
    )
);


//=======================================================
// 640 x 480 VIDEO TIMING
//=======================================================

hvsync_generator u_hvsync (

    .clk (
        hdmi_pix_clk
    ),

    .reset (
        !hdmi_pll_locked
    ),

    .hsync (
        hdmi_hsync
    ),

    .vsync (
        hdmi_vsync
    ),

    .display_on (
        hdmi_de
    ),

    .hpos (
        hdmi_x
    ),

    .vpos (
        hdmi_y
    )
);


//=======================================================
// DUAL-CLOCK FIFO -> HDMI

//=======================================================




//=======================================================
// FRAME SYNCHRONIZER
//
//=======================================================

localparam FRAME_FIND_SOP  = 2'd0;
localparam FRAME_WAIT_HDMI = 2'd1;
localparam FRAME_STREAM    = 2'd2;

reg [1:0] frame_state;

reg [7:0] hdmi_pixel;


// HDMI first active pixel
wire hdmi_frame_start;

assign hdmi_frame_start =
    hdmi_de &&
    (hdmi_x == 11'd0) &&
    (hdmi_y == 10'd0);


//-------------------------------------------------------
// Avalon-ST READY
//-------------------------------------------------------

reg pixel_ready_r;

assign pixel_out_ready = pixel_ready_r;


always @*
begin
    pixel_ready_r = 1'b0;
    case (frame_state)
        FRAME_FIND_SOP:
        begin
            if (pixel_out_valid)
            begin
                if (!pixel_out_startofpacket)
                    pixel_ready_r = 1'b1;
                else
                    pixel_ready_r = 1'b0;
            end
        end
        FRAME_WAIT_HDMI:
        begin
            if (hdmi_frame_start &&
                pixel_out_valid &&
                pixel_out_startofpacket)
            begin
                pixel_ready_r = 1'b1;
            end
        end
        FRAME_STREAM:
        begin
            pixel_ready_r = hdmi_de;
        end
        default:
        begin
            pixel_ready_r = 1'b0;
        end
    endcase
end


//=======================================================
// FRAME STATE MACHINE
//=======================================================

always @(posedge hdmi_pix_clk or posedge video_out_reset_req)
begin
    if (video_out_reset_req)
    begin
        frame_state <= FRAME_FIND_SOP;
        hdmi_pixel <= 8'd0;
    end
    else
    begin
        case (frame_state)
            FRAME_FIND_SOP:
            begin
                if (pixel_out_valid &&
                    pixel_out_startofpacket)
                begin
                    frame_state <= FRAME_WAIT_HDMI;
                end
            end
            FRAME_WAIT_HDMI:
            begin
                if (hdmi_frame_start &&
                    pixel_out_valid &&
                    pixel_out_startofpacket)
                begin
                    // Capture first Sobel pixel
                    hdmi_pixel <= pixel_out_data;
                    if (pixel_out_endofpacket)
                        frame_state <= FRAME_FIND_SOP;
                    else
                        frame_state <= FRAME_STREAM;
                end
            end
            FRAME_STREAM:
            begin
                if (hdmi_de &&
                    pixel_out_valid)
                begin
                    hdmi_pixel <= pixel_out_data;
                    // End of 640x480 Avalon-ST frame
                    if (pixel_out_endofpacket)
                    begin
                        frame_state <= FRAME_FIND_SOP;
                    end
                end
            end
            default:
            begin
                frame_state <= FRAME_FIND_SOP;
                hdmi_pixel <= 8'd0;
            end
        endcase
    end
end


//-------------------------------------------------------
// HDMI VIDEO OUTPUT
//-------------------------------------------------------

assign HDMI_TX_CLK = ~hdmi_pix_clk;

assign HDMI_TX_D = hdmi_de ? hdmi_gray_rgb : 24'h000000;

assign HDMI_TX_DE = hdmi_de;
assign HDMI_TX_HS = hdmi_hsync;
assign HDMI_TX_VS = hdmi_vsync;


//=======================================================
// ADV7513 I2C CONFIGURATION
//=======================================================

I2C_HDMI_Config u_I2C_HDMI_Config (

    .iCLK (
        FPGA_CLK1_50
    ),

    .iRST_N (
        hdmi_pll_locked
    ),

    .I2C_SCLK (
        HDMI_I2C_SCL
    ),

    .I2C_SDAT (
        HDMI_I2C_SDA
    ),

    .HDMI_TX_INT (
        HDMI_TX_INT
    ),

    .READY (
        hdmi_config_ready
    )
);


//=======================================================
// HDMI DEBUG
//=======================================================

reg [25:0] pixel_clock_counter;

reg de_seen;

reg hsync_d;
reg vsync_d;

reg hsync_seen;
reg vsync_seen;

reg [5:0] frame_counter;


//=======================================================
// DEBUG LOGIC
//=======================================================

always @(posedge hdmi_pix_clk or negedge hdmi_pll_locked)
begin

    if (!hdmi_pll_locked)
    begin
        pixel_clock_counter <= 26'd0;
        de_seen <= 1'b0;
        hsync_d <= 1'b1;
        vsync_d <= 1'b1;
        hsync_seen <= 1'b0;
        vsync_seen <= 1'b0;
        frame_counter <= 6'd0;
    end
    else
    begin
        pixel_clock_counter <= pixel_clock_counter + 1'b1;

        if (hdmi_de)
            de_seen <= 1'b1;
        hsync_d <= hdmi_hsync;
        vsync_d <= hdmi_vsync;
        if (hsync_d && !hdmi_hsync)
            hsync_seen <= 1'b1;
        if (vsync_d && !hdmi_vsync)
        begin
           vsync_seen <= 1'b1;

           frame_counter <= frame_counter + 1'b1;
        end
    end
end


//=======================================================
// LED MAPPING
//=======================================================
//
// LED0
//   SW0 / HDMI PLL reset
//
// LED1
//   HDMI PLL locked
//
// LED2
//   ADV7513 configuration ready
//
// LED3
//   25 MHz pixel-clock heartbeat
//
// LED4
//   HDMI DE seen
//
// LED5
//   HSYNC seen
//
// LED6
//   VSYNC seen
//
// LED7
//   frame heartbeat
//=======================================================

assign LED[0] = ~SW[0];

assign LED[1] = hdmi_pll_locked;

assign LED[2] = hdmi_config_ready;

assign LED[3] = pixel_clock_counter[25];

assign LED[4] = de_seen;

assign LED[5] = hsync_seen;

assign LED[6] = vsync_seen;

assign LED[7] = frame_counter[5];


endmodule
