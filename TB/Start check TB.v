`timescale 1ns/1ps

module tb_start_check;

    reg clk;
    reg sampled_data;
    reg start_check_enable;
    reg asy_reset;
    wire start_glitch;

    // Instantiate DUT
    start_check uut (
        .clk_based_on_prescale(clk),
        .sampled_data(sampled_data),
        .start_check_enable(start_check_enable),
        .asy_reset(asy_reset),
        .start_glitch(start_glitch)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period
    end

    // Stimulus
    initial begin
        // Initialize
        asy_reset = 0;
        start_check_enable = 0;
        sampled_data = 1;
        #12;
        
        asy_reset = 1;   // release reset
        #10;

        // Case 1: valid start bit (sampled_data = 0)
        start_check_enable = 1;
        sampled_data = 0;
        #10;

        // Case 2: glitch (sampled_data = 1)
        sampled_data = 1;
        #10;

        // Case 3: disable checking
        start_check_enable = 0;
        sampled_data = 0;
        #10;

        // Re-enable and test again
        start_check_enable = 1;
        sampled_data = 0;
        #10;

        sampled_data = 1;
        #10;

        $stop;
    end

endmodule
