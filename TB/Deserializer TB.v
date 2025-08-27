`timescale 1ns/1ps

module tb_Deserializer;

    reg  clk;
    reg  Deserializer_enable;
    reg  sampled_data;
    reg  sampled_data_valid;
    wire [7:0] parallel_data;

    Deserializer uut (
        .clk_based_on_prescale(clk),
        .Deserializer_enable(Deserializer_enable),
        .sampled_data(sampled_data),
        .sampled_data_valid(sampled_data_valid),
        .parallel_data(parallel_data)
    );

    // clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // period = 10ns
    end

    initial begin
        // Initialization
        Deserializer_enable = 0;
        sampled_data = 0;
        sampled_data_valid = 0;

        #12 Deserializer_enable = 1;  // enable
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(0);
        send_bit(1);
        send_bit(1);

    #100 $finish;
    end

    task send_bit(input bit data);
    begin
        @(posedge clk);
        sampled_data <= data;
        sampled_data_valid <= 1;
        @(posedge clk);
        sampled_data_valid <= 0;
    end
    endtask

endmodule
