`ifndef HVSYNC_GENERATOR_H
`define HVSYNC_GENERATOR_H

        module hvsync_generator(clk, reset, hsync, vsync, display_on, hpos, vpos);

          input clk;
          input reset;
          output reg hsync, vsync;
          output display_on;
          output reg [10:0] hpos;
          output reg [9:0] vpos;

          // declarations for TV-simulator sync parameters
          // horizontal constants
          parameter H_DISPLAY       = 640; // horizontal display width
          parameter H_BACK          =  48; // horizontal left border (back porch)
          parameter H_FRONT         =  16; // horizontal right border (front porch)
          parameter H_SYNC          =  96; // horizontal sync width
          // vertical constants
          parameter V_DISPLAY       = 480; // vertical display height
          parameter V_TOP           =  33; // vertical top border
          parameter V_BOTTOM        =  10; // vertical bottom border
          parameter V_SYNC          =   2; // vertical sync # lines
          // horizontal constants (1024 / 48(FP) / 96(SYNC) / 144(BP))
//				parameter H_DISPLAY       = 1024; // horizontal display width
//				parameter H_FRONT         = 48;   // horizontal right border (front porch)
//				parameter H_SYNC          = 96;   // horizontal sync width
//				parameter H_BACK          = 144;  // horizontal left border (back porch)
//
//				// vertical constants (600 / 3(FP) / 10(SYNC) / 11(BP))
//				parameter V_DISPLAY       = 600;  // vertical display height
//				parameter V_BOTTOM        = 3;    // vertical bottom border (front porch)
//				parameter V_SYNC          = 10;   // vertical sync # lines
//				parameter V_TOP           = 11;   // vertical top border (back porch)
          // derived constants
          parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
          parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
          parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
          parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
          parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
          parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

          wire hmaxxed = (hpos == H_MAX) || reset;	// set when hpos is maximum
          wire vmaxxed = (vpos == V_MAX) || reset;	// set when vpos is maximum

          // horizontal position counter
          always @(posedge clk)
          begin
            hsync <= ~(hpos>=H_SYNC_START && hpos<=H_SYNC_END);
				//hsync <= (hpos>=H_SYNC_START && hpos<=H_SYNC_END);
            if(hmaxxed)
              hpos <= 0;
            else
              hpos <= hpos + 1;
          end

          // vertical position counter
          always @(posedge clk)
          begin
            vsync <= ~(vpos>=V_SYNC_START && vpos<=V_SYNC_END);
				//vsync <= (vpos>=V_SYNC_START && vpos<=V_SYNC_END);
            if(hmaxxed)
              if (vmaxxed)
                vpos <= 0;
              else
                vpos <= vpos + 1;
          end

          // display_on is set when beam is in "safe" visible frame
          assign display_on = (hpos<H_DISPLAY) && (vpos<V_DISPLAY);

        endmodule

`endif
