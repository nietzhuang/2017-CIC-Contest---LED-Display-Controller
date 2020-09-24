module ctrlD(
        input           DCK,
        input           rst,
        input           DEN,

        output reg      CENB
        );

        parameter IDLE = 2'b00, IN = 2'b01, WRITE = 2'b10;
        reg [1:0] cstate, nstate;


        always@(posedge DCK, posedge rst)begin
                if(rst)
                        cstate <= IDLE;
                else
                        cstate <= nstate;
        end

        always@*begin
                case(cstate)
                        IDLE:begin
                                if(DEN)
                                        nstate = IN;
                                else
                                        nstate = IDLE;
                        end
                        IN:begin
                                if(DEN)
                                        nstate = IN;
                                else
                                        nstate = WRITE;
                        end
                        WRITE:begin
                                if(DEN)
                                        nstate = IN;
                                else
                                        nstate = WRITE;
                        end
                        default:
                                nstate = IDLE;
                endcase
        end

        always@*begin        
                case(cstate)
                        IDLE:begin
                                CENB = 1'b1;
                        end
                        IN:begin
                                CENB = DEN;
                        end
                        WRITE:begin
                                CENB = DEN;
                        end
                        default:
                                CENB = 1'b1;
                endcase
        end

endmodule
