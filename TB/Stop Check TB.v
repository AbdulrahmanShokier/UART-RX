`timescale 1ns/1ps

module tb_stop_check;

    reg clk;
    reg sampled_data;
    reg stop_check_enable;
    reg asy_reset;
    wire stop_error;

    // DUT instantiation
    stop_check uut (
        .clk_based_on_prescale(clk),
        .sampled_data(sampled_data),
        .stop_check_enable(stop_check_enable),
        .asy_reset(asy_reset),
        .stop_error(stop_error)
    );

    // Generate clock
    always #5 clk = ~clk;

    initial begin
        // Initial values
        clk = 0;
        sampled_data = 1;
        stop_check_enable = 0;
        asy_reset = 0;

        // Apply reset
        #10 asy_reset = 1;

        // Case 1: stop_check_enable = 1, sampled_data = 1 → valid stop bit
        #10 stop_check_enable = 1;
            sampled_data = 1;
        #10;

        // Case 2: stop_check_enable = 1, sampled_data = 0 → error
        #10 sampled_data = 0;
        #10;

        // Case 3: stop_check_enable = 0 → output should stay 0
        #10 stop_check_enable = 0;
        sampled_data = 0;
        #10 sampled_data = 1;
        #10;

        // Apply async reset again
        #10 asy_reset = 0;
        #10 asy_reset = 1;
        #10;

        $finish;
    end

endmodule
