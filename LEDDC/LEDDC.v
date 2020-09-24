`include "ctrlD.v"
`include "ctrlG.v"
`include "data_in.v"
`include "pwm_gen.v"
`include "sram_512x16.v"

`timescale 1ns/10ps
module LEDDC( DCK, DAI, DEN, GCK, Vsync, mode, rst, OUT);
input           DCK;
input           DAI;
input           DEN;
input           GCK;
input           Vsync;
input           mode;
input           rst;
output [15:0]   OUT;

        wire            first, read_start;
        wire            out_en;
        wire            first_read_done, read_done, frameout_done;
        wire            Vsync_pulse;
        wire [15:0]     QA;
        wire [8:0]      AA;
        wire            CENA;  // as a write enable.
        wire [8:0]      AB;
        wire [15:0]     DB;
        wire            CENB;  // as a read enable.

        wire [15:0]     QA_buf;
        wire [8:0]      AB_buf, AA_buf;
        wire [15:0]     tmp_buf;
        wire            CENA_buf, CENB_buf;


        ctrlD u_ctrld(.DCK(DCK),
                      .rst(rst),
                      .DEN(DEN),
                      .CENB(CENB)
                      );
                      
        ctrlG u_ctrlg(.GCK(GCK),
                      .rst(rst),
                      .Vsync(Vsync),
                      .Vsync_pulse(Vsync_pulse),
                      .first(first),
                      .read_start(read_start),
                      .first_read_done(first_read_done),
                      .frameout_done(frameout_done),
                      .CENA(CENA),
                      .out_en(out_en)
                      );

        data_in u_data_in(.DCK(DCK),
                          .rst(rst),
                          .DAI(DAI),
                          .DEN(DEN),
                          .AB(AB),
                          .DB(DB)
                          );
                          
        pwm_gen u_pwm_gen(.GCK(GCK),
                          .rst(rst),
                          .QA(QA),
                          .CENA(CENA),
                          .Vsync(Vsync),
                          .Vsync_pulse(Vsync_pulse),
                          .out_en(out_en),
                          .mode(mode),
                          .first(first),
                          .read_start(read_start),
                          .frameout_done(frameout_done),
                          .first_read_done(first_read_done),
                          .read_done(read_done),
                          .AA(AA),
                          .OUT(OUT),

                          .QA_buf(QA_buf),
                          .AA_buf(AA_buf),
                          .CENA_buf(CENA_buf),
                          .AB_buf(AB_buf),
                          .tmp_buf(tmp_buf),
                          .CENB_buf(CENB_buf)
                          );
                          
        sram_512x16 u_sram_0(.QA(QA),
                             .AA(AA),
                             .CLKA(GCK),
                             .CENA(CENA),
                             .AB(AB),
                             .DB(DB),
                             .CLKB(DCK),
                             .CENB(CENB)
                             );

        sram_512x16 u_sram_1(.QA(QA_buf),
                             .AA(AA_buf),
                             .CLKA(GCK),
                             .CENA(CENA_buf),
                             .AB(AB_buf),
                             .DB(tmp_buf),
                             .CLKB(GCK),
                             .CENB(CENB_buf)
                             );
endmodule                          
