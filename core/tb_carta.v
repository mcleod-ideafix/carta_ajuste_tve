`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2023 22:01:08
// Design Name: 
// Module Name: tb_carta
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_carta;
  reg clk;
  wire [7:0] r, g, b;
  wire csync_n;
  
  carta_ajuste_tve_50hz_pal la_carta (
    .clk(clk),
    .red(r),
    .green(g),
    .blue(b),
    .hsync_n(),
    .vsync_n(),
    .csync_n(csync_n)
  );
  integer f;
  
  initial begin
    clk = 0;
    f = $fopen ("cuadro_imagen.raw", "wb");
    @(negedge csync_n);
    @(posedge clk);
    repeat (944*625) begin
      if (csync_n == 0)
        $fwrite (f, "%c%c%c", 0, 128, 255);
      else
        $fwrite (f, "%c%c%c", r, g, b);
      @(posedge clk);
    end
    $fclose (f);
    $display ("Fotograma volcado. Fin de la simulacion");
    $finish;
  end
  
  always begin
    clk = #(500/14.75) ~clk;
  end
endmodule
