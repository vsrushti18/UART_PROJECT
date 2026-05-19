`timescale 1ns/1ps
module u_baud #(
    parameter XTAL_CLK = 50000000,
    parameter BAUD = 115200
)(
    input  sys_clk,
    input  sys_rst_l,
    output reg uart_clk
);
    localparam integer CLK_DIV = XTAL_CLK / (BAUD * 16 *2);

    reg [$clog2(CLK_DIV)-1:0] baud_cnt;

    always @(posedge sys_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
            baud_cnt <= 0;
            uart_clk <= 0;
        end else begin
            if (baud_cnt == CLK_DIV - 1) begin
                baud_cnt <= 0;
                uart_clk <= ~uart_clk;
            end else begin
                baud_cnt <= baud_cnt + 1;
            end
        end
    end
endmodule
