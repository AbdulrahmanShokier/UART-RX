`timescale 1ns/1ps

module parity_check_tb;

    reg clk;
    reg parity_type;
    reg sampled_data;
    reg parity_check_enable;
    wire parity_error;

    // DUT instance
    parity_check uut (
        .clk_based_on_prescale(clk),
        .parity_type(parity_type),
        .sampled_data(sampled_data),
        .parity_check_enable(parity_check_enable),
        .parity_error(parity_error)
    );

    // Clock generation (period = 10ns)
    always #5 clk = ~clk;

    // Task to send 8 data bits + 1 parity bit
    task send_frame;
        input [7:0] data;
        input       parity_bit;
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                sampled_data = data[i];
                @(posedge clk);
            end
            // Send parity bit
            sampled_data = parity_bit;
            @(posedge clk);
        end
    endtask

    initial begin
        // Init
        clk = 0;
        parity_check_enable = 0;
        sampled_data = 0;
        parity_type = 0;

        // Start simulation
        #20;
        parity_check_enable = 1;

        // Test 1: Even parity, data=8'b10101010 (number of 1s=4 so parity=0)
        parity_type = 0; // even
        $display("Sending even parity test...");
        send_frame(8'b10101010, 1'b0);
        #10;
        $display("Parity error (should be 0): %b", parity_error);

        // Test 2: Odd parity, data=8'b10101010 (number of 1s=4 so parity=1 to make it odd)
        parity_type = 1; // odd
        $display("Sending odd parity test...");
        send_frame(8'b10101010, 1'b1);
        #10;
        $display("Parity error (should be 0): %b", parity_error);

        // Test 3: Error case (wrong parity bit)
        parity_type = 0; // even
        $display("Sending wrong parity test...");
        send_frame(8'b10101010, 1'b1); // should be 0 but we send 1
        #10;
        $display("Parity error (should be 1): %b", parity_error);

        $stop;
    end

endmodule
