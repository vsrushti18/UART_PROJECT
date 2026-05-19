`timescale 1ns/1ps
`include "u_baud.v"
`include "u_xmit.v"
`include "u_rec.v"

module uart #(
    parameter WORD_LEN = 8,
    parameter XTAL_CLK = 50_000_000,
    parameter BAUD = 115200
)(
    input sys_clk,
    input sys_rst_l,
    
    input xmitH,
    input [WORD_LEN-1:0] xmit_dataH,
    output uart_XMIT_dataH,
    output xmit_doneH,
    output xmit_active,
    
    input uart_REC_dataH,
    output [WORD_LEN-1:0] rec_dataH,
    output rec_readyH,
    output rec_busy
);
    wire uart_clk;

    u_baud #(
        .XTAL_CLK(XTAL_CLK),
        .BAUD(BAUD)
    ) U_BAUD (
        .sys_clk(sys_clk),
        .sys_rst_l(sys_rst_l),
        .uart_clk(uart_clk)
    );

    u_xmit #(
        .WORD_LEN(WORD_LEN)
    ) U_XMIT (
        .sys_rst_l(sys_rst_l),
        .uart_clk(uart_clk),
        .xmitH(xmitH),
        .xmit_dataH(xmit_dataH),
        .uart_xmit_dataH(uart_XMIT_dataH),
        .xmit_doneH(xmit_doneH),
        .xmit_active(xmit_active)
    );

    u_rec #(
        .WORD_LEN(WORD_LEN)
    ) U_REC (
        .sys_rst_l(sys_rst_l),
        .uart_clk(uart_clk),
        .uart_REC_dataH(uart_REC_dataH),
        .rec_dataH(rec_dataH),
        .rec_readyH(rec_readyH),
        .rec_busy(rec_busy)
    );

endmodule
