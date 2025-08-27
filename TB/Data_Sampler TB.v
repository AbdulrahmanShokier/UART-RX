`timescale 1ns/1ps

module tb_Data_Sampler;

  reg  [5:0] prescale;
  reg        RX_IN;
  reg        clk_based_on_prescale;
  reg        data_sampler_enable;
  reg  [5:0] edge_count;
  wire       sampled_data;

  // Instantiate DUT
  Data_Sampler dut (
    .prescale(prescale),
    .RX_IN(RX_IN),
    .clk_based_on_prescale(clk_based_on_prescale),
    .data_sampler_enable(data_sampler_enable),
    .edge_count(edge_count),
    .sampled_data(sampled_data)
  );

  // Generate clock
  initial begin
    clk_based_on_prescale = 0;
    forever #5 clk_based_on_prescale = ~clk_based_on_prescale; // period = 10 ns
  end

  // Stimulus
  initial begin
    // Initialize
    prescale = 6'd8;  
    RX_IN = 0;
    data_sampler_enable = 1;
    edge_count = 0;

    // Monitor signals
    $monitor("Time=%0t | edge_count=%0d | RX_IN=%b | data_majority=%b | sampled_data=%b",
             $time, edge_count, RX_IN, dut.data_majority, sampled_data);

    // Simulate RX_IN samples
    #12 edge_count = 3; RX_IN = 1;  // First sample
    #10 edge_count = 4; RX_IN = 0;  // Second sample
    #10 edge_count = 5; RX_IN = 1;  // Third sample (should output majority=1)

    #20 edge_count = 3; RX_IN = 0;  // First sample next bit
    #10 edge_count = 4; RX_IN = 0;  // Second sample
    #10 edge_count = 5; RX_IN = 1;  // Third sample (majority=0)

    #50 $finish;
  end

endmodule
