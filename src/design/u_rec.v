`timescale 1ns/1ps

    module u_rec #(
        parameter WORD_LEN = 8
    )(
        input sys_rst_l,
        input uart_clk,
        input uart_REC_dataH,
        output reg [WORD_LEN-1:0] rec_dataH,
        output reg rec_readyH,
        output reg rec_busy
    );

    parameter idle = 2'b00, start = 2'b01, data = 2'b10, stop = 2'b11;

    reg [1:0] st;
    reg [WORD_LEN-1:0] sh_reg;
    reg [2:0] bcnt;
    reg [3:0] ccnt;

    reg rx_ff1, rx_ff2;

    always @ (posedge uart_clk or negedge sys_rst_l) begin
        if(!sys_rst_l) begin
            st <= idle;
            sh_reg <= 0;
            rec_dataH <= 0;
            bcnt <= 0;
            ccnt <= 0;
            rec_readyH <= 1;
            rec_busy <= 0;
            rx_ff1 <= 1;
            rx_ff2 <= 1;
        end else begin
            rx_ff1 <= uart_REC_dataH;
            rx_ff2 <= rx_ff1;
            case(st)
            idle: begin
                rec_dataH  <= 0;
                rec_busy <= 0;
                ccnt<=0;
                bcnt<=0;
                if(rx_ff2==1'b0) begin
                    rec_readyH <= 1'b0;
                    st <= start;
                    rec_busy <= 1;
                end 
            end
            start: begin
                rec_readyH <= 1'b0;
                if(ccnt==14) begin
                    ccnt <= 0;
                    if(rx_ff2==1'b0) begin
                        st <= data;
                    end else begin 
                        st <= idle;
                    end
                end else begin
                    ccnt <= ccnt + 1;
                end
            end
            data: begin
                rec_readyH <= 1'b0;
                rec_busy <= 1'b1;
                if(ccnt==15) begin
                    ccnt <= 0;
                    if(bcnt==WORD_LEN-1) begin
                        bcnt <= 0;
                        st <= stop;
                    end else begin
                        bcnt <= bcnt + 1;
                    end
                end else begin 
                    if(ccnt==6) begin
                        rec_dataH = {rx_ff2, rec_dataH[WORD_LEN-1:1]};
                    end
                    ccnt <= ccnt + 1;
                end
            end
            stop: begin
                if(ccnt==15) begin
                    ccnt <= 0;
                    st <= idle;
                    if(rx_ff2==1'b1) begin
                        rec_busy <= 1'b0;
                        rec_readyH <= 1'b1;
                    end else begin
                        rec_busy <= 1'b0;
                        rec_readyH <= 1'b0;
                        rec_dataH <= 0;
                    end
                end else begin
                    ccnt <= ccnt + 1;
                    rec_busy <= 1'b1;
                    rec_readyH <= 1'b0;
                end
            end
            default: begin
                st <= idle;
                sh_reg <= 0;
                rec_readyH <= 1;
                rec_busy <= 0;
                ccnt <= 0;
                bcnt <= 0;
            end
            endcase
        end
    end
    endmodule
