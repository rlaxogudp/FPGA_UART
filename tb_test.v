`timescale 1ns / 1ps

module tb_command_cu;
    reg clk, rst;
    reg [7:0] rx_fifo_data;
    reg rx_trigger;
    wire runstop, clear;

    // DUT
    command_cu dut (
        .clk(clk),
        .rst(rst),
        .rx_fifo_data(rx_fifo_data),
        .rx_trigger(rx_trigger),
        .runstop(runstop),
        .clear(clear)
    );

    // clock gen
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        rx_trigger = 0;
        rx_fifo_data = 8'h00;
        #20;
        rst = 0;

        // case 1: R (0x52)
        #10 rx_fifo_data = 8'h52;
            rx_trigger = 1;
        #10 rx_trigger = 0;

        // case 2: S (0x53)
        #20 rx_fifo_data = 8'h53;
            rx_trigger = 1;
        #10 rx_trigger = 0;

        // case 3: C (0x43)
        #20 rx_fifo_data = 8'h43;
            rx_trigger = 1;
        #10 rx_trigger = 0;

        #50 $finish;
    end
endmodule
