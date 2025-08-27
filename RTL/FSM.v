module FSM
(
    input asy_reset,
    input clk,                     // clk of the tx
    input RX_IN,
    input parity_enable,
    input parity_error,            // parity check
    input start_glitch,            // start check
    input stop_error,              // stop check
    input [3:0] edge_count,        // edge bit counter
    input [4:0] bit_count          // edge bit counter
    output Deserializer_enable,    //deserializer
    output data_valid,
    output parity_check_enable,    // parity check 
    output data_sampler_enable,    // data sampler
    output start_check_enable,     // start check
    output stop_check_enable,      // stop check
    output edge_bit_enable
);

parameter idle_state    = 1 ;
parameter start_state   = 2 ;
parameter data_state    = 3 ;
parameter parity_state  = 4 ;
parameter end_state     = 5 ;

reg [2:0] current_state;
reg [2:0] next_state; 

always@(posedge clk or negedge asy_reset)
begin
    if(!asy_reset)
        current_state <= idle_state;
    else
        current_state <= next_state;
end

always@(*)
begin
    case(current_state)
    
    idle_state:
    begin
        if(RX_IN == 0)
        begin
            next_state<= start_state;
            edge_bit_enable     <=1;
            data_sampler_enable <=1;
            start_check_enable  <=1;
        end
        else 
        begin
            next_state<= idle_state;
            edge_bit_enable     <=0;
            data_sampler_enable <=0;
            start_check_enable  <=0;            
        end
    end

    start_state:
    begin
        if(start_glitch)
        begin
            next_state<= idle_state;
            edge_bit_enable     <=0;
            data_sampler_enable <=0;
            start_check_enable  <=0;
        end
        else
        begin
            Deserializer_enable <=1;
            next_state<= data_state;
            parity_check_enable <=1;



    end








endmodule