module UART_RX (
    input  wire       clk_based_on_prescale, // Oversampling clock (baud_rate * prescale)
    input  wire       asy_reset,            // Active-low asynchronous reset
    input  wire       RX_IN,               // Serial input
    input  wire [5:0] prescale,            // Prescale value (8, 16, 32)
    input  wire       parity_enable,        // 1: Enable parity, 0: No parity
    input  wire       parity_type,          // 0: Even parity, 1: Odd parity
    output wire [7:0] parallel_data,        // 8-bit received data
    output wire       data_valid            // High when data is valid
);

    // Internal signals
    wire       start_glitch;
    wire       parity_error;
    wire       stop_error;
    wire [5:0] edge_count;
    wire [4:0] bit_count;
    wire       sampled_data;
    wire       sampled_data_valid;
    wire       Deserializer_enable;
    wire       parity_check_enable;
    wire       data_sampler_enable;
    wire       start_check_enable;
    wire       stop_check_enable;
    wire       shift_enable;
    wire       edge_bit_enable;

    // Instantiate FSM
    FSM FSM_inst (
        .asy_reset(asy_reset),
        .clk_based_on_prescale(clk_based_on_prescale),
        .RX_IN(RX_IN),
        .parity_enable(parity_enable),
        .parity_error(parity_error),
        .start_glitch(start_glitch),
        .stop_error(stop_error),
        .edge_count(edge_count),
        .bit_count(bit_count),
        .prescale(prescale),
        .Deserializer_enable(Deserializer_enable),
        .data_valid(data_valid),
        .parity_check_enable(parity_check_enable),
        .data_sampler_enable(data_sampler_enable),
        .start_check_enable(start_check_enable),
        .stop_check_enable(stop_check_enable),
        .shift_enable(shift_enable),
        .edge_bit_enable(edge_bit_enable)
    );

    // Instantiate Edge_Bit_Counter
    Edge_Bit_Counter Edge_Bit_Counter_inst (
        .asy_reset(asy_reset),
        .edge_bit_enable(edge_bit_enable),
        .clk_based_on_prescale(clk_based_on_prescale),
        .prescale(prescale),
        .edge_count(edge_count),
        .bit_count(bit_count)
    );

    // Instantiate Data_Sampler
    Data_Sampler Data_Sampler_inst (
        .asy_reset(asy_reset),
        .prescale(prescale),
        .RX_IN(RX_IN),
        .clk_based_on_prescale(clk_based_on_prescale),
        .data_sampler_enable(data_sampler_enable),
        .edge_count(edge_count),
        .sampled_data(sampled_data),
        .sampled_data_valid(sampled_data_valid)
    );

    // Instantiate Deserializer
    Deserializer Deserializer_inst (
        .clk_based_on_prescale(clk_based_on_prescale),
        .Deserializer_enable(Deserializer_enable),
        .shift_enable(shift_enable),
        .sampled_data(sampled_data),
        .sampled_data_valid(sampled_data_valid),
        .asy_reset(asy_reset),
        .parallel_data(parallel_data)
    );

    // Instantiate Start_Check
    start_check Start_Check_inst (
        .clk_based_on_prescale(clk_based_on_prescale),
        .sampled_data(sampled_data),
        .start_check_enable(start_check_enable),
        .asy_reset(asy_reset),
        .sampled_data_valid(sampled_data_valid),
        .start_glitch(start_glitch)
    );

    // Instantiate Parity_Check
    parity_check Parity_Check_inst (
        .asy_reset(asy_reset),
        .clk_based_on_prescale(clk_based_on_prescale),
        .parity_type(parity_type),
        .sampled_data(sampled_data),
        .parity_check_enable(parity_check_enable),
        .sampled_data_valid(sampled_data_valid),
        .parity_error(parity_error)
    );

    // Instantiate Stop_Check
    stop_check Stop_Check_inst (
        .clk_based_on_prescale(clk_based_on_prescale),
        .sampled_data(sampled_data),
        .stop_check_enable(stop_check_enable),
        .asy_reset(asy_reset),
        .sampled_data_valid(sampled_data_valid),
        .stop_error(stop_error)
    );

endmodule