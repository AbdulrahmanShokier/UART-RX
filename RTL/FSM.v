module FSM
(
    input asy_reset,
    input clk_based_on_prescale,        // clk of the rx
    input RX_IN,
    input parity_enable,                // signal recieved out of the rx block
    input parity_error,                 // parity check
    input start_glitch,                 // start check
    input stop_error,                   // stop check
    input [5:0] edge_count,             // edge bit counter
    input [4:0] bit_count,              // edge bit counter
    output reg Deserializer_enable,     //deserializer
    output reg data_valid,
    output reg parity_check_enable,     // parity check 
    output reg data_sampler_enable,     // data sampler
    output reg start_check_enable,      // start check
    output reg stop_check_enable,       // stop check
    output reg edge_bit_enable          // edge bit counter
);

parameter idle_state    = 3'b000;
parameter start_state   = 3'b001;
parameter data_state    = 3'b010;
parameter parity_state  = 3'b011;
parameter stop_state    = 3'b100;


reg [2:0] current_state;
reg [2:0] next_state;

reg parity_enable_save;

always@(posedge clk_based_on_prescale or negedge asy_reset)
begin
    if(!asy_reset)
        current_state <= idle_state;
    else
        current_state <= next_state;
end

always @(posedge clk_based_on_prescale or negedge asy_reset) 
begin
    if (!asy_reset)
        parity_enable_save <= 1'b0;
    else if (current_state == idle_state && RX_IN == 1'b0)
        parity_enable_save <= parity_enable; // <-- changed: sample synchronously (no latch)
    else
        parity_enable_save <= parity_enable_save;
end

always@(*)
begin
    Deserializer_enable  = 0;
    data_valid           = 0;
    parity_check_enable  = 0;
    data_sampler_enable  = 0;
    start_check_enable   = 0;
    stop_check_enable    = 0;
    edge_bit_enable      = 0;

    case(current_state)
    
    idle_state:
    begin
        if(RX_IN == 0)
        begin
            next_state = start_state;
            edge_bit_enable     =1;
            data_sampler_enable =1;
            start_check_enable  =1;
            parity_enable_save  = parity_enable;
        end
        else 
        begin
            next_state = idle_state;           
        end
    end

    start_state:
    begin
        if(start_glitch)
        begin
            next_state <= idle_state;
        end
        else
        begin
            next_state = data_state;
            edge_bit_enable     =1;
            Deserializer_enable =1;   
            parity_check_enable =1;
            data_sampler_enable =1;
        end
    end

    data_state:
    begin
        if(bit_count<8)
        begin
            next_state = data_state;
            edge_bit_enable     =1;
            Deserializer_enable =1;   
            parity_check_enable =1;
            data_sampler_enable =1;
        end
        else if(bit_count==8)
        begin
            if(parity_enable_save==0)
            begin
                next_state = stop_state;
                stop_check_enable   =1;
                edge_bit_enable     =1;
                Deserializer_enable =1;  
                parity_check_enable =0; // we do not need to check on the parity bit
                data_valid          =0; // not yet we need to check on the stop bit
                data_sampler_enable =1;
            end
            else
            begin
                next_state = parity_state;
                edge_bit_enable     =1;    // we need the edge counter always
                Deserializer_enable =1;    // we don't the deserializer anymore
                parity_check_enable =1;    // now we need the parity check block 
                data_valid          =0;    // not yet we need to check on the parity error if existed
                data_sampler_enable =1;    
            end
        end
    end

    parity_state:
    begin
        if(parity_error)
            next_state = idle_state; // all other enable signals will become zero by default
        else
        begin
            next_state = stop_state;
            stop_check_enable   =1;
            edge_bit_enable     =1;
            Deserializer_enable =1;  // it will spit out the data but not related to its correction or not 
            data_sampler_enable =1; 
            data_valid          =0;  // not yet we need to check on the stop bit  
        end          
    end

    stop_state:
    begin
        if(!stop_error)
        begin
            next_state = idle_state;
            Deserializer_enable =1;  // it will spit out the data but not related to its correction or not 
            data_valid          =1;  // not the data is correct after checking on both parity and stop bits
        end
        else
        begin
           next_state = idle_state;
           data_valid =0;            // the data was correpted and not correct :(
        end
    end
    endcase
end
endmodule