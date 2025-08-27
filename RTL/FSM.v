module FSM
(
    input RX_IN,
    input parity_enable,
    input parity_error,            // parity check
    input start_glitch,            // start check
    input stop_error,              // stop check
    input [3:0] edge_count,        // edge bit counter
    input [4:0] bit_count          // edge bit counter
    output Deserializer_enable,    //deserializer
    output data_valid,
    output parity_check_enable,   // parity check 
    output data_sampler_enable,   // data sampler
    output start_check_enable,    // start check
    output stop_check_enable,     // stop check
    output edge_bit_enable
);




endmodule