module vga_hdmi (
	input  logic clk_i,
	input  logic rst_i,
	input  logic hdmi_data_i,
	
	output logic rst_frame_o,
	
	output logic hdmi_ena_o,
	output logic hsync_o, 
	output logic vsync_o,
	output logic data_ena_o,
	output logic [23:0] hdmi_data_o
);
    /* Hien thi ra tv
	// Horizontal (VGA 640x480 @60Hz)
	parameter H_DISPLAY      = 640;
	parameter H_FRONT_PORCH  = 16;
	parameter H_SYNC         = 96;
	parameter H_BACK_PORCH   = 48;
	parameter H_TOTAL        = 800;

	// Vertical
	parameter V_DISPLAY      = 480;
	parameter V_FRONT_PORCH  = 10;
	parameter V_SYNC         = 2;
	parameter V_BACK_PORCH   = 33;
	parameter V_TOTAL        = 525;
	*/
	// horizontal constants (1024x600 @60Hz)
	parameter H_DISPLAY       = 1024; // horizontal display width
	parameter H_FRONT_PORCH   = 48;   // horizontal right border (front porch)
	parameter H_SYNC          = 96;   // horizontal sync width
	parameter H_BACK_PORCH    = 144;  // horizontal left border (back porch)
   parameter H_TOTAL         = 1312;
	// vertical constants 
	parameter V_DISPLAY       = 600;  // vertical display height
	parameter V_FRONT_PORCH   = 3;    // vertical bottom border (front porch)
	parameter V_SYNC          = 10;   // vertical sync # lines
	parameter V_BACK_PORCH    = 11;   // vertical top border (back porch)
	parameter V_TOTAL         = 624;
	
	logic hsync;
	assign hsync_o = hsync;
	logic vsync;
	assign vsync_o = vsync;
	logic data_ena;
	assign data_ena_o = data_ena;
	
	logic [10:0] pixelH, pixelV; 
	logic h_ena, v_ena;

	logic hsync_start, hsync_stop, h_display_start, h_display_stop;
	assign hsync_start    = pixelH >= (H_SYNC - 1);
	assign hsync_stop     = pixelH == (H_TOTAL - 1); //h_max
	assign h_display_start  = pixelH == (H_SYNC + H_BACK_PORCH - 1 - 1);
	assign h_display_stop   = pixelH == (H_SYNC + H_BACK_PORCH + H_DISPLAY - 1 - 1);
	
	logic vsync_start, vsync_stop, v_display_start, v_display_stop;
	assign vsync_start    = pixelV >= (V_SYNC - 1);
	assign vsync_stop     = pixelV == (V_TOTAL - 1); // v_max
	assign v_display_start  = pixelV == (V_SYNC + V_BACK_PORCH - 1);
	assign v_display_stop   = pixelV == (V_SYNC + V_BACK_PORCH + V_DISPLAY - 1);
	
	always_ff @(posedge clk_i) begin
		if (!rst_i) begin
			hsync <= 1;
			vsync <= 1; 
			pixelH <= 0;
			pixelV <= 0;
			h_ena <= 0;
			v_ena <= 0;
			rst_frame_o <= 0;
		end else begin
			if (pixelV == V_BACK_PORCH) 
				rst_frame_o <= 1;
			else 
				rst_frame_o <= 0;
					
			//H
			if (hsync_stop) 
				pixelH <= 0;
			else 
				pixelH <= pixelH + 1;
		
			if (hsync_start && !hsync_stop) 
				hsync <= 1;
			else 
				hsync <= 0;
				
			if (h_display_start) 
				h_ena <= 1;
			else if (h_display_stop)
				h_ena <= 0;
			
			//V
			if (hsync_stop) begin
				if (vsync_stop) 
					pixelV <= 0;
				else 
					pixelV <= pixelV + 1;
				
				if (vsync_start && !vsync_stop)
					vsync <= 1;
				else 
					vsync <= 0;
					
				if (v_display_start) 
					v_ena <= 1;
				else if (v_display_stop)
					v_ena <= 0;
			end
		end
	end
	
	// dataEnable signal
	logic buffer;
	assign hdmi_ena_o = buffer;
	always @(posedge clk_i) begin
		if(!rst_i) begin
			data_ena <= 0;
			buffer   <= 0;
		end else begin
			data_ena <= buffer;
			buffer   <= h_ena && v_ena;
		end
	end
	
	assign hdmi_data_o = hdmi_data_i ? 24'hFFFFFF : 24'h0;

endmodule
			