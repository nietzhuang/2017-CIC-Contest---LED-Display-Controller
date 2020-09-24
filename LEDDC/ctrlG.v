module ctrlG(
        input           GCK,
        input           rst,
        input           Vsync,
        input           Vsync_pulse,
        input           first,
        input           read_start,
        input           first_read_done,
        input           frameout_done,

        output reg      CENA, 
        output reg      out_en
        );

        parameter IDLE = 2'b00, R_O = 2'b01;
        reg [1:0] cstate, nstate;


        always@(posedge GCK, posedge rst)begin
                if(rst)
                        cstate <= IDLE;
                else
                        cstate <= nstate;
        end

        always@*begin
                case(cstate)
                        IDLE:begin
                                if(read_start || (!first && Vsync_pulse))
                                        nstate = R_O;
                                else
                                        nstate = IDLE;
                        end
                        R_O:begin
                                if(frameout_done || first_read_done)
                                        nstate = IDLE;
                                else
                                        nstate = R_O;
                        end
                        default:begin
                                nstate = IDLE;
                        end
                endcase
        end

        always@*begin        
                case(cstate)
                        IDLE:begin
                                CENA = 1'b1;
                                out_en = 1'b0;
                        end
                        R_O:begin
                                CENA = #1 ((first && !read_start) || (!first && !read_start));
                                out_en = (!first && Vsync);
                        end
                        default:begin
                                CENA = 1'b1;
                                out_en = 1'b0;
                        end
                endcase
        end

endmodule
