//////////////////////////////////////////////////////////////////////////////////
// Company: ZX Projects
// Engineer: Miguel Angel Rodriguez Jodar
// 
// Create Date: 21.07.2023 19:30:20
// Design Name: 
// Module Name: carta_ajuste_tve_50hz_pal
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
`timescale 1ns / 1ps
`default_nettype none

module carta_ajuste_tve_50hz_pal (
    input wire clk,  // 14.75 MHz
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue,
    output reg hsync_n,
    output reg vsync_n,
    output reg csync_n
    );

    localparam ETAPAS_PIPELINE = 12; 
    
    // Line period       64 us (Micro-seconds)
    // Line blanking     12.05 +- 0.25 us
    // Line sync         4.7 +- 0.1 us
    // Front porch:      1.65 +- 0.1 us
    // Active video area 51.95 us
    localparam HTOTAL  = 944;   // 64 us * 14.75 MHz
    localparam VTOTAL  = 625;
    localparam HSYNC   = 70;    // 4.7 * 14.75
    localparam HBPORCH = 81;    // 5.7 * 14.75
    localparam HFPORCH = 25;    // 1.65 * 14.75
    localparam HACTIVE = 768;
    
    localparam EQPULSE = 35;    // 2.35 * 14.75
    localparam FSPULSE = 403;   //27.3 * 14.75
    localparam IFSYNC  = 70;    // 4.7 * 14.75
    localparam HHALF   = HTOTAL/2;
        
    reg [10:0] hcont = 0;  // contador horizontal (cuenta pixeles)
    reg [10:0] vcont = 0;  // contador vertical (cuenta scans)

    reg [7:0] barras[0:399];
    initial $readmemh ("valores_barras_rejilla.hex", barras);
    
    reg [7:0] circulo[0:255];
    initial $readmemh ("valores_cuarto_circunferencia.hex", circulo);

    reg [0:0] tve[0:256*80-1];
    reg logopixel;
    initial $readmemh ("logo_tve.hex", tve); 
    
    // Generamos los sincronismos en función de los contadores de pixel y scan
    reg h0,v0,c0;
    always @* begin
      if (vcont >= 0 && vcont < 3 || vcont >= 312 && vcont < 315)
        v0 = 0;
      else
        v0 = 1;
      if (hcont >= 0 && hcont < HSYNC)
        h0 = 0;
      else
        h0 = 1;
      
      if (vcont == 0 || vcont == 1 || vcont == 313 || vcont == 314) begin
        if (hcont >= 0 && hcont < FSPULSE || hcont >= HHALF && hcont < (HHALF+FSPULSE))
          c0 = 0;
        else
          c0 = 1;
      end
      else if (vcont == 3 || vcont == 4 || vcont == 310 || 
               vcont == 311 || vcont == 315 || vcont == 316 || 
               vcont == 622 || vcont == 623 || vcont == 624) begin
        if (hcont >= 0 && hcont < EQPULSE || hcont >= HHALF && hcont < (HHALF+EQPULSE))
          c0 = 0;
        else
          c0 = 1;
      end
      else if (vcont == 2) begin
        if (hcont >= 0 && hcont < FSPULSE || hcont >= HHALF && hcont < (HHALF+EQPULSE))
          c0 = 0;
        else
          c0 = 1;
      end
      else if (vcont == 312) begin
        if (hcont >= 0 && hcont < EQPULSE || hcont >= HHALF && hcont < (HHALF+FSPULSE))
          c0 = 0;
        else
          c0 = 1;
      end
      else if (vcont == 317) begin
        if (hcont >= 0 && hcont < EQPULSE)
          c0 = 0;
        else
          c0 = 1;
      end
      else begin
        if (hcont >= 0 && hcont < HSYNC)
          c0 = 0;
        else
          c0 = 1;
      end
    end  
       
    always @(posedge clk) begin
      // Actualización de los contadores. Estoy usando timings como el del Spectrum 48K
      if (hcont == HTOTAL-1) begin
        hcont <= 0;
        if (vcont == VTOTAL-1)        
          vcont <= 0;
        else
          vcont <= vcont + 1;
      end
      else
        hcont <= hcont + 1;
    end    
    
    reg [10:0] x [1:ETAPAS_PIPELINE];
    reg [10:0] y [1:ETAPAS_PIPELINE];
    reg       hs [1:ETAPAS_PIPELINE];
    reg       vs [1:ETAPAS_PIPELINE];
    reg       cs [1:ETAPAS_PIPELINE];
    reg [7:0] r  [1:ETAPAS_PIPELINE];
    reg [7:0] g  [1:ETAPAS_PIPELINE];
    reg [7:0] b  [1:ETAPAS_PIPELINE];
    
    integer i;
    initial begin
      for (i=1; i<=ETAPAS_PIPELINE; i=i+1) begin
        x[i]  = 0;
        y[i]  = 0;
        hs[i] = 1;
        vs[i] = 1;
        cs[i] = 1;
        r[i]  = 0;
        g[i]  = 0;
        b[i]  = 0;
      end
    end
        
    `define ETP 1
    `define xa   x[`ETP]
    `define ya   y[`ETP]
    `define hsa hs[`ETP]
    `define vsa vs[`ETP]
    `define csa cs[`ETP]
    `define ra   r[`ETP]
    `define ga   g[`ETP]
    `define ba   b[`ETP]
    `define xp   x[`ETP+1]
    `define yp   y[`ETP+1]
    `define hsp hs[`ETP+1]
    `define vsp vs[`ETP+1]
    `define csp cs[`ETP+1]
    `define rp   r[`ETP+1]
    `define gp   g[`ETP+1]
    `define bp   b[`ETP+1]    

    //////////////////////////////////////////////////////////////////////////
    //                       PIXEL PIPELINE                                 // 
    //////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
      ///////////////////////////////////////////////
      // Fondo gris
      ///////////////////////////////////////////////
      if (hcont >= HSYNC+HBPORCH && hcont < HSYNC+HBPORCH+HACTIVE)
        `xa <= hcont - (HSYNC+HBPORCH);
      else
        `xa <= 11'h7FF;   // Para indicar que estamos fuera de la zona activa
      if (vcont >= 23 && vcont < 311)  // OJO: la linea anterior, la 22, es la que se reserva para el WSS
        `ya <= (vcont - 23)*2 + 1;     //      Por tanto, empezamos a contar las lineas activas desde la 23 (comenzando por 0)
      else if (vcont >= 335 && vcont < 623)
        `ya <= (vcont - 335)*2;
      else
        `ya <= 11'h7FF;  // coordenada Y fuera de zona activa

      // Comenzamos poniendo el color de fondo para toda la carta: gris medio.
      // En la última etapa, pondremos a 0 la imagen cuando estemos fuera de la zona activa
      `ra  <= 8'h80;
      `ga  <= 8'h80;
      `ba  <= 8'h80;

      `hsa <= h0;
      `vsa <= v0;
      `csa <= c0;

      ///////////////////////////////////////////////
      // Rejilla blanca
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      // La rejilla tiene 40 pixeles de espacio, con 2 pixeles de grosor
      if (`xa == 23+40*0  || `xa == 24+40*0  ||
          `xa == 23+40*1  || `xa == 24+40*1  ||
          `xa == 23+40*2  || `xa == 24+40*2  ||
          `xa == 23+40*3  || `xa == 24+40*3  ||
          `xa == 23+40*4  || `xa == 24+40*4  ||
          `xa == 23+40*5  || `xa == 24+40*5  ||
          `xa == 23+40*6  || `xa == 24+40*6  ||
          `xa == 23+40*7  || `xa == 24+40*7  ||
          `xa == 23+40*8  || `xa == 24+40*8  ||
          `xa == 23+40*9  || `xa == 24+40*9  ||
          `xa == 23+40*10 || `xa == 24+40*10 ||
          `xa == 23+40*11 || `xa == 24+40*11 ||
          `xa == 23+40*12 || `xa == 24+40*12 ||
          `xa == 23+40*13 || `xa == 24+40*13 ||
          `xa == 23+40*14 || `xa == 24+40*14 ||
          `xa == 23+40*15 || `xa == 24+40*15 ||
          `xa == 23+40*16 || `xa == 24+40*16 ||
          `xa == 23+40*17 || `xa == 24+40*17 ||
          `xa == 23+40*18 || `xa == 24+40*18 ||
          `ya == 7+40*0  || `ya == 8+40*0  ||
          `ya == 7+40*1  || `ya == 8+40*1  ||
          `ya == 7+40*2  || `ya == 8+40*2  ||
          `ya == 7+40*3  || `ya == 8+40*3  ||
          `ya == 7+40*4  || `ya == 8+40*4  ||
          `ya == 7+40*5  || `ya == 8+40*5  ||
          `ya == 7+40*6  || `ya == 8+40*6  ||
          `ya == 7+40*7  || `ya == 8+40*7  ||
          `ya == 7+40*8  || `ya == 8+40*8  ||
          `ya == 7+40*9  || `ya == 8+40*9  ||
          `ya == 7+40*10 || `ya == 8+40*10 ||
          `ya == 7+40*11 || `ya == 8+40*11 ||
          `ya == 7+40*12 || `ya == 8+40*12 ||
          `ya == 7+40*13 || `ya == 8+40*13 ||
          `ya == 7+40*14 || `ya == 8+40*14
          ) begin
        `rp <= 8'hFF;
        `gp <= 8'hFF;
        `bp <= 8'hFF;
      end 

      `undef ETP
      `define ETP 2

      ///////////////////////////////////////////////
      // Rectangulo naranja
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 105 && `xa <= 662 && `ya >= 89 && `ya <= 486) begin
        `rp <= 255;
        `gp <= 144;
        `bp <= 56;
      end 

      `undef ETP
      `define ETP 3

      ///////////////////////////////////////////////
      // Castellación
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa < 24 || (`xa >= 744 && `xa < 768) || `ya < 24 || (`ya >= 552 && `ya < 576)) begin
        if (`xa < 24 || `xa >= 744) begin
          if (`ya >= 12      && `ya < 8+40*1  ||
              `ya >= 8+40*2  && `ya < 8+40*3  ||
              `ya >= 8+40*4  && `ya < 8+40*5  ||
              `ya >= 8+40*6  && `ya < 8+40*7  ||
              `ya >= 8+40*8  && `ya < 8+40*9  ||
              `ya >= 8+40*10 && `ya < 8+40*11 ||
              `ya >= 8+40*12 && `ya < 8+40*13 ||
              `ya >= 8+40*14 && `ya < 8+40*15 ) begin
            if (`xa < 12 || (`xa >=744 && `xa < (744+12))) begin
              `rp <= 8'h00;
              `gp <= 8'h00;
              `bp <= 8'h00;
            end
            else begin
              `rp <= 8'hFF;
              `gp <= 8'hFF;
              `bp <= 8'hFF;
            end
          end
          else if (`ya >= 0  && `ya < 12      ||
              `ya >= 8+40*1  && `ya < 8+40*2  ||
              `ya >= 8+40*3  && `ya < 8+40*4  ||
              `ya >= 8+40*5  && `ya < 8+40*6  ||
              `ya >= 8+40*7  && `ya < 8+40*8  ||
              `ya >= 8+40*9  && `ya < 8+40*10 ||
              `ya >= 8+40*11 && `ya < 8+40*12 ||
              `ya >= 8+40*13 && `ya < 8+40*14 ) begin
            if (`xa < 12 || (`xa >=744 && `xa < (744+12))) begin
              `rp <= 8'hFF;
              `gp <= 8'hFF;
              `bp <= 8'hFF;
            end
            else begin
              `rp <= 8'h00;
              `gp <= 8'h00;
              `bp <= 8'h00;
            end
          end
        end
        else if (`ya < 24 || `ya >= 552) begin
          if (`xa >= 24+40*0  && `xa < 24+40*1  ||
              `xa >= 24+40*2  && `xa < 24+40*3  ||
              `xa >= 24+40*4  && `xa < 24+40*5  ||
              `xa >= 24+40*6  && `xa < 24+40*7  ||
              `xa >= 24+40*8  && `xa < 24+40*9  ||
              `xa >= 24+40*10 && `xa < 24+40*11 ||
              `xa >= 24+40*12 && `xa < 24+40*13 ||
              `xa >= 24+40*14 && `xa < 24+40*15 ||
              `xa >= 24+40*16 && `xa < 24+40*17 ) begin
            if (`ya < 12) begin
              `rp <= 8'hFF;
              `gp <= 8'hFF;
              `bp <= 8'hFF;
            end
            else if (`ya < 24 || `ya >= 552+12) begin
              `rp <= 8'h00;
              `gp <= 8'h00;
              `bp <= 8'h00;
            end
            else begin
              `rp <= 8'h80;
              `gp <= 8'h80;
              `bp <= 8'h80;
            end
          end
          else if (`xa >= 24+40*1  && `xa < 24+40*2  ||
                   `xa >= 24+40*3  && `xa < 24+40*4  ||
                   `xa >= 24+40*5  && `xa < 24+40*6  ||
                   `xa >= 24+40*7  && `xa < 24+40*8  ||
                   `xa >= 24+40*9  && `xa < 24+40*10 ||
                   `xa >= 24+40*11 && `xa < 24+40*12 ||
                   `xa >= 24+40*13 && `xa < 24+40*14 ||
                   `xa >= 24+40*15 && `xa < 24+40*16 ||
                   `xa >= 24+40*17 && `xa < 24+40*18 ) begin
            if (`ya < 12 || (`ya >= 552 && `ya < 552+12 )) begin
              `rp <= 8'h00;
              `gp <= 8'h00;
              `bp <= 8'h00;
            end
            else if (`ya >= 552+12) begin
              `rp <= 8'hFF;
              `gp <= 8'hFF;
              `bp <= 8'hFF;
            end
            else begin
              `rp <= 8'h80;
              `gp <= 8'h80;
              `bp <= 8'h80;
            end
          end
        end
      end

      `undef ETP
      `define ETP 4

      ///////////////////////////////////////////////
      // Circulo base
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

       if (`ya >= 32 && `ya <= 543 && `xa >= 127 && `xa <= 639) begin
         if (`ya <= 207 && `xa <= 383) begin
           if (`xa >= (383 - circulo[`ya-32])) begin
             `rp <= 8'd93;
             `gp <= 8'd149;
             `bp <= 8'd196;
           end
         end
         else if (`ya <= 287 && `xa <= 383) begin
           if (`xa >= (383 - circulo[`ya-32])) begin
             `rp <= 8'd234;
             `gp <= 8'd214;
             `bp <= 8'd61;
           end
         end
         else if (`ya <= 207 && `xa >= 384) begin
           if (`xa <= (384 + circulo[`ya-32])) begin
             `rp <= 8'd93;
             `gp <= 8'd149;
             `bp <= 8'd196;
           end
         end
         else if (`ya <= 287 && `xa >= 384) begin
           if (`xa <= (384 + circulo[`ya-32])) begin
             `rp <= 8'd19;
             `gp <= 8'd15;
             `bp <= 8'd216;
           end
         end
         else if (`ya <= 447 && `xa <= 383) begin
           if (`xa >= (383 - circulo[255 - (`ya - 288)])) begin
             `rp <= 8'h00;
             `gp <= 8'h00;
             `bp <= 8'h00;
           end
         end
         else if (`ya <= 447 && `xa >= 384) begin
           if (`xa <= (384 + circulo[255 - (`ya - 288)])) begin
             `rp <= 8'hFF;
             `gp <= 8'hFF;
             `bp <= 8'hFF;
           end
         end
         else if (`ya <= 488) begin
           if (`xa >= (383 - circulo[255 - (`ya - 288)]) && `xa <= (384 + circulo[255 - (`ya - 288)])) begin
             `rp <= 8'hFF;
             `gp <= 8'hFF;
             `bp <= 8'hFF;
           end
         end
         else begin
           if (`xa >= (383 - circulo[255 - (`ya - 288)]) && `xa <= (384 + circulo[255 - (`ya - 288)])) begin
             `rp <= 8'd93;
             `gp <= 8'd149;
             `bp <= 8'd196;
           end
         end
       end
           
      `undef ETP   
      `define ETP 5

      ///////////////////////////////////////////////
      // Rejilla de barras de frecuencia
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 184 && `xa <= 583 && `ya >= 368 && `ya <= 447) begin
        `rp <= barras[`xa-184];
        `gp <= barras[`xa-184];
        `bp <= barras[`xa-184];
      end
        
      `undef ETP   
      `define ETP 6

      ///////////////////////////////////////////////
      // Barras de color y B/N
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 224 && `xa < 543 && `ya >= 208 && `ya < 368) begin
        if (`xa < 224+80) begin
          if (`ya < 288) begin
            `rp <= 8'd0;
            `gp <= 8'd225;
            `bp <= 8'd195;
          end
          else begin
            `rp <= 8'd51;
            `gp <= 8'd51;
            `bp <= 8'd51;
          end
        end
        else if (`xa < 224+80*2) begin
          if (`ya < 288) begin
            `rp <= 8'd0;
            `gp <= 8'd219;
            `bp <= 8'd46;
          end
          else begin
            `rp <= 8'd102;
            `gp <= 8'd102;
            `bp <= 8'd102;
          end
        end
        else if (`xa < 224+80*3) begin
          if (`ya < 288) begin
            `rp <= 8'd231;
            `gp <= 8'd7;
            `bp <= 8'd240;
          end
          else begin
            `rp <= 8'd153;
            `gp <= 8'd153;
            `bp <= 8'd153;
          end
        end
        else begin
          if (`ya < 288) begin
            `rp <= 8'd246;
            `gp <= 8'd31;
            `bp <= 8'd59;
          end
          else begin
            `rp <= 8'd204;
            `gp <= 8'd204;
            `bp <= 8'd204;
          end
        end
      end              

      `undef ETP   
      `define ETP 7

      ///////////////////////////////////////////////
      // Señal de pulso
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;

      if (`xa >= 244 && `ya >= 448 && `xa < 244+280 && `ya <= 488) begin
        `rp <= 8'h00;
        `gp <= 8'h00;
        `bp <= 8'h00;
        if (`xa == 302 || `xa == 303) begin
          `rp <= 8'hFF;
          `gp <= 8'hFF;
          `bp <= 8'hFF;
        end
      end
      
      `undef ETP   
      `define ETP 8

      ///////////////////////////////////////////////
      // Caja superior
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if (`xa >= 305 && `ya >= 47 && `xa < (305+160) && `ya <= 87 && !(`xa >= 315 && `ya >= 57 && `xa < 455 && `ya <= 77)) begin
        `rp <= 8'hFF;
        `gp <= 8'hFF;
        `bp <= 8'hFF;
      end
      
      logopixel <= tve[(`ya - 109)*256 + (`xa - 305)];
      
      `undef ETP   
      `define ETP 9

      ///////////////////////////////////////////////
      // Identificativo de la cadena (logo TVE)
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if (`xa >= 305 && `ya >= 109 && `xa < (305+160) && `ya < 189) begin
        if (logopixel == 1'b1) begin
          `rp <= 8'd234;
          `gp <= 8'd214;
          `bp <= 8'd61;
        end
      end
      
      `undef ETP   
      `define ETP 10

      ///////////////////////////////////////////////
      // Parrilla de centro
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if ( ((`ya == 287 || `ya == 288) && `xa >= 244 && `xa <= 523) ||
           ((`xa == 383 || `xa == 384) && `ya >= 228 && `ya <= 347) ||
           ((`xa == 263 || `xa == 264) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 303 || `xa == 304) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 343 || `xa == 344) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 423 || `xa == 424) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 463 || `xa == 464) && `ya >= 268 && `ya <= 307) ||
           ((`xa == 503 || `xa == 504) && `ya >= 268 && `ya <= 307) ||
           ((`ya == 247 || `ya == 248) && `xa >= 363 && `xa <= 403) ||
           ((`ya == 327 || `ya == 328) && `xa >= 363 && `xa <= 403) ) begin
        `rp <= 8'hFF;
        `gp <= 8'hFF;
        `bp <= 8'hFF;
      end   
      
      `undef ETP   
      `define ETP 11

      ///////////////////////////////////////////////
      // Distinguir zona de blanking de zona activa. Ultima etapa
      ///////////////////////////////////////////////
      `xp  <= `xa;
      `yp  <= `ya;
      `hsp <= `hsa;
      `vsp <= `vsa;
      `csp <= `csa;
      `rp  <= `ra;
      `gp  <= `ga;
      `bp  <= `ba;
      
      if (`ya == 11'h7FF || `xa == 11'h7FF) begin
        `rp <= 8'h00;
        `gp <= 8'h00;
        `bp <= 8'h00;  // 60h sólo en simulación. En hard real, 00h
      end

      `undef ETP
      `define ETP 12
      
      ///////////////////////////////////////////////
      // FIN del pipeline
      ///////////////////////////////////////////////
      red     <= `ra;
      green   <= `ga;
      blue    <= `ba;
      hsync_n <= `hsa;
      vsync_n <= `vsa;
      csync_n <= `csa;
    end    
endmodule

`default_nettype wire
