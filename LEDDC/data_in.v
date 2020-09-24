module data_in(
        input                   DCK,
        input                   rst,
        input                   DAI,
        input                   DEN,

        output reg [8:0]        AB,
        output reg [15:0]       DB
        );

        reg [15:0]      cnt_DCK;
        reg [8:0]       cnt_pixel;
        reg [15:0]      data_in_tmp;


        always@(posedge DCK, posedge rst)begin
                if(rst)
                        cnt_DCK <= 16'b0;
                else if(DEN)
                        cnt_DCK <= cnt_DCK + 1;
                else
                        cnt_DCK <= 16'b0;
        end

        always@(posedge DCK, posedge rst)begin
                if(rst)
                        cnt_pixel <= 9'b0;
                else if(cnt_DCK == 16'd15)
                        cnt_pixel <= cnt_pixel + 1;
        end
        
        always@(posedge DCK, posedge rst)begin
                if(rst)
                        data_in_tmp <= 16'b0;
                else if(DEN)
                        data_in_tmp <= (data_in_tmp >> 1) + {DAI, 15'b0};
        end

        always@*begin
                if(DEN)
                        AB = 9'b0;
                else
                        AB = cnt_pixel - 1;
        end

        always@*begin
                DB = data_in_tmp;
        end

endmodule
