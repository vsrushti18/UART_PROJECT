`timescale 1ns/1ps
module u_xmit #(
    parameter WORD_LEN = 8
)(
    input  sys_rst_l,
    input  uart_clk,
    input  xmitH,
    input  [WORD_LEN-1:0] xmit_dataH,
    output reg uart_xmit_dataH,
    output reg xmit_doneH,
    output reg xmit_active
);
    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0]          st;
    reg [WORD_LEN-1:0] sh_reg;
    reg [2:0]          bcnt;
    reg [3:0]          ccnt;

    reg tx_req;
    reg [WORD_LEN-1:0]tx_data_req;

    always@(posedge uart_clk or negedge sys_rst_l) begin
    	if(!sys_rst_l) begin
		tx_req <= 1'b0;
		tx_data_req <= 0;
	end else begin
		if(xmitH && !tx_req && st ==IDLE) begin
			tx_req <= 1'b1;
			tx_data_req <= xmit_dataH;
		end else if(st==START) begin
			tx_req <= 1'b0;
		end
	end
    end

    always @(posedge uart_clk or negedge sys_rst_l) begin
    if (!sys_rst_l) begin
        st <= IDLE;
        bcnt <= 0;
        ccnt <= 0;
        sh_reg <= 0;
        uart_xmit_dataH <= 1'b1;
        xmit_doneH <= 1'b1;
        xmit_active <= 1'b0;

    end else begin

        case(st)

        IDLE: begin
            uart_xmit_dataH <= 1'b1;
            xmit_active <= 1'b0;
            xmit_doneH <= 1'b1;
            ccnt <= 0;
            bcnt <= 0;

            if(tx_req) begin
                xmit_doneH <= 1'b0;
                sh_reg <= tx_data_req;
                st <= START;
                uart_xmit_dataH <= 1'b0; 
                xmit_active <= 1'b1;
            end
        end

        START: begin
	    uart_xmit_dataH <= 1'b0;
            if(ccnt == 15) begin
                ccnt <= 0;
                st   <= DATA;
                bcnt <= 0;
            end else begin
                ccnt <= ccnt + 1;
            end
        end

        DATA: begin
            if(ccnt == 0)begin
                uart_xmit_dataH <= sh_reg[0];
            end
            if(ccnt == 15) begin
                ccnt <= 0;
                sh_reg <= sh_reg >> 1;
                if(bcnt == WORD_LEN-1) begin
                    st <= STOP;
                    bcnt <= 0;
                end else begin
                    bcnt <= bcnt + 1;
                end
            end else begin
                ccnt <= ccnt + 1;
            end
        end

        STOP: begin
            uart_xmit_dataH <= 1'b1;
            if(ccnt == 15) begin
                ccnt <= 0;
                st <= IDLE;

                xmit_doneH <= 1'b1;
                xmit_active <= 1'b0;

            end else begin
                ccnt <= ccnt + 1;
            end
        end

        default: begin
		st <= IDLE;
	end
        endcase
    end
end
endmodule
