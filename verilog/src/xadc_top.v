/* Module Name: xadc_top.v
   Author:      Jak Huyen
   Description: Top level code to take ADC data and display it on segment display
   Notes:       
*/
module xadc_top (
  input clkIn,
  input rstIn,
  input xadcN0In,
  input xadcP0In,
  input vp_in,
  input vn_in,
  output [7:0] anOut,
  output [6:0] segOut,
  output reg dpOut
);

  // Since each step of the ADC is 1/4095 = 0.0002442, the integer representation 
  // of this will be 2442, which is 12'h98A
  localparam reg [11:0] MULTI_FACTOR = 12'h98A;

  localparam integer DIV_NUM_DISP = 100000 // synthesis translate_off
                                  -  99990 // synthesis translate_on
                                    ;

  localparam integer DIV_NUM_DATA = 1000000 // synthesis translate_off
                                  -  999900 // synthesis translate_on
                                  ;

  integer index;

  reg [23:0] calcVoltR;
  reg [3:0] segDigitsR [7:0];
  reg [6:0] segR;
  reg [7:0] anR;

  wire [6:0] segW [7:0];
  wire [11:0] adcDataW;
  wire rstW;
  wire clk10KHzW;
  wire clk100HzW;

  assign anOut   = anR;
  assign segOut  = segR;

  reset_sync rst_sync (
    .clkIn(clkIn),
    .rstIn(rstIn),
    .rstOut(rstW)
  );

  genvar i;
  for (i = 0; i < 8; i = i + 1) begin
    seg_display seg_disp (
      .clkIn(clkIn),
      .rstIn(rstW),
      .digitIn(segDigitsR[i]),
      .segOut(segW[i])
    );
  end

  xadc_if adc_if (
    .clkIn(clkIn),
    .rstIn(rstW),
    .xadcN0In(xadcN0In),
    .xadcP0In(xadcP0In),
    .vp_in(vp_in),
    .vn_in(vn_in),
    .adcDataOut(adcDataW)
  );

  // Divide the 100 MHz clock into a 1 KHz clock for the display
  // Allows for a good refresh rate without sacrificing brightness of the display.
  clk_divider #(.DIV_NUM(DIV_NUM_DISP)) clk_div_disp
  (
    .clkIn(clkIn),
    .rstIn(rstW),
    .clkOut(clk10KHzW)
  );

  // Divide the 100 MHz clock into a 100 Hz clock for the data
  clk_divider #(.DIV_NUM(DIV_NUM_DATA)) clk_div_data
  (
    .clkIn(clkIn),
    .rstIn(rstW),
    .clkOut(clk100HzW)
  );

  always @ (posedge rstW, posedge clk100HzW) begin
    if (rstW == 1) begin
      calcVoltR <= 24'h0;

      for (index = 0; index < 8; index = index + 1) begin
        segDigitsR[index] <= 0;
      end
    end

    else if (clk100HzW == 1) begin
      calcVoltR <= adcDataW * MULTI_FACTOR;

      if (adcDataW == 12'hFFF) begin
        // segDigitsR highest index will correspond to the leftmost digit of the display.
        segDigitsR[7] <= 1;
        segDigitsR[6] <= 0;
        segDigitsR[5] <= 0;
        segDigitsR[4] <= 0;
        segDigitsR[3] <= 0;
        segDigitsR[2] <= 0;
        segDigitsR[1] <= 0;
        segDigitsR[0] <= 0;
      end

      else begin
        // segDigitsR highest index will correspond to the leftmost digit of the display.
        segDigitsR[7] <= 0;
        segDigitsR[6] <= (calcVoltR >= 1000000) ?(calcVoltR / 1000000)          :0;
        segDigitsR[5] <= (calcVoltR >= 100000)  ?(calcVoltR % 1000000) / 100000 :0;
        segDigitsR[4] <= (calcVoltR >= 10000)   ?(calcVoltR % 100000)  / 10000  :0;
        segDigitsR[3] <= (calcVoltR >= 1000)    ?(calcVoltR % 10000)   / 1000   :0;
        segDigitsR[2] <= (calcVoltR >= 100)     ?(calcVoltR % 1000)    / 100    :0;
        segDigitsR[1] <= (calcVoltR >= 10)      ?(calcVoltR % 100)     / 10     :0;
        segDigitsR[0] <= (calcVoltR % 10);
      end
    end
  end

  // Cycles through the 8 digits of the display, outputting the correct anode and segments to be lit up.
  always @ (posedge rstW, posedge clk10KHzW) begin
    if (rstW == 1) begin
      anR  <= 8'h7F;
      segR <= 7'h7F;
    end

    else if (clk10KHzW == 1) begin
      dpOut <= 1;
      // segW highest index will correspond to the leftmost digit of the display.
      case (anR)
        8'h7F   : begin 
                    anR   <= 8'hBF;
                    segR  <= segW[6];
                  end

        8'hBF   : begin
                    anR   <= 8'hDF;
                    segR  <= segW[5];
                  end

        8'hDF   : begin
                    anR   <= 8'hEF;
                    segR  <= segW[4];
                  end

        8'hEF   : begin
                    anR   <= 8'hF7;
                    segR  <= segW[3];
                  end

        8'hF7   : begin
                    anR   <= 8'hFB;
                    segR  <= segW[2];
                  end

        8'hFB   : begin
                    anR   <= 8'hFD;
                    segR  <= segW[1];
                  end

        8'hFD   : begin
                    anR   <= 8'hFE;
                    segR  <= segW[0];
                  end

        8'hFE   : begin
                    anR   <= 8'h7F;
                    segR  <= segW[7];
                    dpOut <= 0;
                  end

        default : begin
                    anR  <= 8'h7F;
                    segR <= 7'h40;
                  end
      endcase
    end
  end
endmodule