`timescale 1ns / 1ps

module UART_RX_tb;

    // Testbench signals
    reg        clk_based_on_prescale;
    reg        asy_reset;
    reg        RX_IN;
    reg [5:0]  prescale;
    reg        parity_enable;
    reg        parity_type;
    wire [7:0] parallel_data;
    wire       data_valid;

    // Instantiate UART_RX
    UART_RX DUT (
        .clk_based_on_prescale(clk_based_on_prescale),
        .asy_reset(asy_reset),
        .RX_IN(RX_IN),
        .prescale(prescale),
        .parity_enable(parity_enable),
        .parity_type(parity_type),
        .parallel_data(parallel_data),
        .data_valid(data_valid)
    );

    // Clock generation (10ns period, 100MHz for simplicity)
    initial begin
        clk_based_on_prescale = 0;
        forever #5 clk_based_on_prescale = ~clk_based_on_prescale;
    end

    // Task to send a UART frame
    task send_frame;
        input [7:0] data;
        input       use_parity;
        input       parity_type;
        input [5:0] prescale;
        input       introduce_parity_error;
        input       introduce_stop_error;
        integer i, j;
        reg parity_bit;
    begin
        // Calculate parity
        parity_bit = use_parity ? (^data ^ parity_type) : 0; // Even: 0 if even 1s, Odd: 1 if even 1s
        if (introduce_parity_error)
            parity_bit = ~parity_bit;

        // Start bit
        RX_IN = 0;
        for (j = 0; j < prescale; j = j + 1)
            @(posedge clk_based_on_prescale);

        // Data bits
        for (i = 0; i < 8; i = i + 1) begin
            RX_IN = data[i];
            for (j = 0; j < prescale; j = j + 1)
                @(posedge clk_based_on_prescale);
        end

        // Parity bit
        if (use_parity) begin
            RX_IN = parity_bit;
            for (j = 0; j < prescale; j = j + 1)
                @(posedge clk_based_on_prescale);
        end

        // Stop bit
        RX_IN = introduce_stop_error ? 0 : 1;
        for (j = 0; j < prescale; j = j + 1)
            @(posedge clk_based_on_prescale);

        // Idle
        RX_IN = 1;
        for (j = 0; j < prescale; j = j + 1)
            @(posedge clk_based_on_prescale);
    end
    endtask

    // Test procedure
    initial begin
        // Initialize signals
        asy_reset = 0;
        RX_IN = 1; // Idle state
        parity_enable = 0;
        parity_type = 0;
        prescale = 8;
        #20;
        asy_reset = 1;
        #20;

        // Test 1: 8N1, prescale=8, data=0xA5 (10100101), valid frame
        $display("Test 1: 8N1, prescale=8, data=0xA5");
        parity_enable = 0;
        send_frame(8'hA5, 0, 0, 8, 0, 0);
        @(posedge data_valid);
        if (parallel_data == 8'hA5 && data_valid == 1)
            $display("Test 1 Passed: parallel_data=%h, data_valid=%b", parallel_data, data_valid);
        else
            $display("Test 1 Failed: parallel_data=%h, data_valid=%b", parallel_data, data_valid);
        #100;

        // Test 2: 8E1, prescale=16, data=0x5A (01011010), valid frame
        $display("Test 2: 8E1, prescale=16, data=0x5A");
        prescale = 16;
        parity_enable = 1;
        parity_type = 0; // Even parity
        send_frame(8'h5A, 1, 0, 16, 0, 0);
        @(posedge data_valid);
        if (parallel_data == 8'h5A && data_valid == 1)
            $display("Test 2 Passed: parallel_data=%h, data_valid=%b", parallel_data, data_valid);
        else
            $display("Test 2 Failed: parallel_data=%h, data_valid=%b", parallel_data, data_valid);
        #100;

        // Test 3: 8E1, prescale=32, data=0x3C (00111100), parity error
        $display("Test 3: 8E1, prescale=32, data=0x3C, parity error");
        prescale = 32;
        parity_enable = 1;
        parity_type = 0;
        send_frame(8'h3C, 1, 0, 32, 1, 0);
        #1000; // Wait for frame to complete
        if (data_valid == 0)
            $display("Test 3 Passed: data_valid=%b (no output due to parity error)", data_valid);
        else
            $display("Test 3 Failed: data_valid=%b", data_valid);
        #100;

        // Test 4: 8N1, prescale=8, data=0xFF, stop error
        $display("Test 4: 8N1, prescale=8, data=0xFF, stop error");
        prescale = 8;
        parity_enable = 0;
        send_frame(8'hFF, 0, 0, 8, 0, 1);
        #300;
        if (data_valid == 0)
            $display("Test 4 Passed: data_valid=%b (no output due to stop error)", data_valid);
        else
            $display("Test 4 Failed: data_valid=%b", data_valid);
        #100;

        // Test 5: 8N1, prescale=16, data=0x00, valid frame
        $display("Test 5: 8N1, prescale=16, data=0x00");
        prescale = 16;
        parity_enable = 0;
        send_frame(8'h00, 0, 0, 16, 0, 0);
        @(posedge data_valid);
        if (parallel_data == 8'h00 && data_valid == 1)
            $display("Test 5 Passed: parallel_data=%h, data_valid=%b", parallel_data, data_valid);
        else
            $display("Test 5 Failed: parallel_data=%h, data_valid=%b", parallel_data, data_valid);
        #100;

        $display("Simulation complete!");
        $finish;
    end

endmodule