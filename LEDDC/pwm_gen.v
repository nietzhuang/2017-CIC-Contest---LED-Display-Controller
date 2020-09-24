module pwm_gen(
        input                   GCK,
        input                   rst,
        input      [15:0]       QA,
        input                   CENA,
        input                   Vsync,
        output                  Vsync_pulse,
        input                   out_en,
        input                   mode,

        output reg              first,            // indicate the first output, the display controller only store pixel data, and don't check ou                                                     put.
        output                  read_start,       // set a timing to read next pixel data in advance.
        output                  first_read_done,
        output reg              read_done,
        output                  frameout_done,
        output reg [8:0]        AA,
        output reg [15:0]       OUT,

        // Buffer control signals for handling the output of round 1.
        input      [15:0]       QA_buf,
        output reg [8:0]        AA_buf,
        output reg              CENA_buf,
        output reg [8:0]        AB_buf,
        output reg [15:0]       tmp_buf,
        output reg              CENB_buf
        );
        
        wire            GCKn;
        reg             Vsync_delay;
        reg             round;
        wire [8:0]      read_offset, buffer_offset;
        reg [4:0]       cnt_read;
        reg [4:0]       cnt_buf;
        reg [15:0]      cnt_out;        //! there might be a solution that does not count so precisely.
        reg [5:0]       cnt_line;
        reg             buffer_done;
        reg [15:0]      out_tmp[15:0];
        reg [15:0]      tmp[15:0];      // the result of half of out_tmp.

        reg [4:0]       i;


        assign Vsync_pulse = Vsync && (!Vsync_delay);
        assign read_start = (first && (cnt_line == 6'd32)) || (!mode && !first && (cnt_out >= 16'd65518) && (cnt_out <= 16'd65534))
                                                           || (mode && !first && (cnt_out >= 16'd32750) && (cnt_out <= 16'd32766));
        assign first_read_done = first && (cnt_read == 5'd17);
        assign frameout_done = (cnt_line == 6'd32) && (cnt_out == 16'd65535);

        assign GCKn = !GCK;

        always@(posedge GCK, posedge rst)begin
                if(rst)
                        first <= 1'b1;
                else if(first_read_done)
                        first <= 1'b0;
        end

        always@(posedge GCKn, posedge rst)begin  //! use negtive edge trigger here, there might be a method avoiding this.
                if(rst)
                        cnt_read <= 5'b0;
                else if(cnt_read == 5'd17)  // count 1 to 16 and addtionally delay 1 clk.
                        cnt_read <= 5'b0;
                else if(!CENA)
                        cnt_read <= cnt_read + 1;
        end

        always@(posedge GCK, posedge rst)begin
                if(rst)
                        read_done <= 1'b0;
                else if(!first && (cnt_read == 5'd17))
                        read_done <= 1'b1;
                else if(read_start)
                        read_done <= 1'b0;
        end


        always@(posedge GCK, posedge rst)begin
                if(rst)
                        cnt_line <= 6'b0;
                else begin
                                if(Vsync_pulse && (cnt_line == 6'd32))  // count from 1 to 32.
                                        cnt_line <= 6'd1;
                                else if(Vsync_pulse)
                                        cnt_line <= cnt_line + 1;
                end
        end

        always@(posedge GCK, posedge rst)begin
                if(rst)
                        cnt_out <= 16'b0;
                else if(!mode && (cnt_out == 16'd65535))
                        cnt_out <= 16'b0;
                else if(mode && (cnt_out == 16'd32767))
                        cnt_out <= 16'b0;
                else if(out_en)
                        cnt_out <= cnt_out + 1;
        end

        always@(posedge GCK, posedge rst)begin
                if(rst)
                        round <= 1'b1;
                else if((cnt_line == 6'd32) && (cnt_out == 16'd32749))
                        round <= !round;
        end


        // Delay signals.
        always@(posedge GCK, posedge rst)begin
                if(rst)
                        Vsync_delay <= 1'b0;
                else
                        Vsync_delay <= Vsync;
        end


        // Read pixel data.
        assign read_offset = cnt_line << 4;

        always@*begin
                if(first)
                        AA = #1 (cnt_read-1);
                else
                        AA = #1 ((cnt_read-1) + read_offset);
        end


        // Store pixel data tn temp buffer.
        always@(posedge GCK, posedge rst)begin
                if(rst)begin
                        for(i=0; i <= 15'd0; i = i + 1)
                                out_tmp[i] <= 16'b0;
                end
                else if(mode)begin
                        if((!CENA) && (!round))
                                out_tmp[cnt_read-2] <= QA;
                        else if((!CENA_buf) && round)
                                out_tmp[cnt_buf-1] <= QA_buf;
                end
                else if(!mode)begin
                        if(!CENA)
                                out_tmp[cnt_read-2] <= QA;
                end
        end

        // Output in PWM manner.
        always@*begin
                if(!mode && out_en)begin
                        for(i=0;i <= 15; i = i + 1)
                                OUT[i] = (cnt_out < out_tmp[i])? 1'b1 : 1'b0;
                end
                else if(mode && out_en)begin
                        for(i=0;i <= 15; i = i + 1)begin
                                if(!round)
                                        OUT[i] = (cnt_out < tmp[i])? 1'b1 : 1'b0;
                                else
                                        OUT[i] = (cnt_out < tmp[i])? 1'b1 : 1'b0;


                        end
                end
                else
                        OUT = 16'b0;
        end
        always@*begin
                if(!round)begin
                        for(i=0;i <= 15; i = i + 1)
                                tmp[i] = (out_tmp[i]>>1) + out_tmp[i][0];
                end
                else begin
                        for(i=0;i <= 15; i = i + 1)
                                tmp[i] = (out_tmp[i]>>1);
                end
        end
        
        
        // Store pixel data in SRAM buffer for round 1.
        always@(posedge GCK, posedge rst)begin
                if(rst)
                        cnt_buf <= 4'b0;
                else if(buffer_done && (!CENA_buf))
                        cnt_buf <= cnt_buf + 1;
                else if(buffer_done)
                        cnt_buf <= 4'b0;
                else if(Vsync)
                        cnt_buf <= cnt_buf + 1;

        end
        always@(posedge GCK, posedge rst)begin
                if(rst)
                        buffer_done <= 1'b1;
                else if(cnt_out == 16'd1)
                        buffer_done <= 1'b0;
                else if(cnt_out == 16'd17)
                        buffer_done <= 1'b1;
        end
        always@*begin
                if((!round) && (!buffer_done))
                        CENB_buf = #1 !Vsync;
                else
                        CENB_buf = #1 1'b1;
        end
        
        
        assign buffer_offset = ((cnt_line-1) << 4);
        always@*begin
                AB_buf =  #1 cnt_buf + buffer_offset;
        end

        always@*begin
                tmp_buf = #1 out_tmp[cnt_buf];  // output to SRAM buffer.
        end


        //Read output data from SRAM buffer for round 1.
        always@*begin
                CENA_buf = #1 (!(mode && !first && round && (cnt_out >= 16'd32750) && (cnt_out <= 16'd32766)));
        end

        always@*begin
                if(cnt_line == 16'd32)
                        AA_buf = #1 cnt_buf;
                else
                        AA_buf = #1 cnt_buf + buffer_offset + 9'd16;
        end

endmodule
