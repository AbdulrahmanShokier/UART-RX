module FSM
(
    input asy_reset,
    input clk_based_on_prescale,
    input RX_IN,  
    input parity_enable,
    input parity_error,
    input start_glitch,
    input stop_error,
    input [5:0] edge_count,
    input [4:0] bit_count,
    input [5:0] prescale,
    output reg Deserializer_enable,
    output reg data_valid,
    output reg parity_check_enable,
    output reg data_sampler_enable,
    output reg start_check_enable,
    output reg stop_check_enable,
    output reg shift_enable,
    output reg edge_bit_enable
);

parameter idle_state    = 3'b000;
parameter start_state   = 3'b001;
parameter data_state    = 3'b010;
parameter parity_state  = 3'b011;
parameter stop_state    = 3'b100;

reg [2:0] current_state;
reg [2:0] next_state;
reg parity_enable_save;

always @(posedge clk_based_on_prescale or negedge asy_reset)
begin
    if (!asy_reset)
        current_state <= idle_state;
    else
        current_state <= next_state;
end

always @(posedge clk_based_on_prescale or negedge asy_reset) 
begin
    if (!asy_reset)
        parity_enable_save <= 1'b0;
    else if (current_state == idle_state && RX_IN == 1'b0)
        parity_enable_save <= parity_enable;
    else
        parity_enable_save <= parity_enable_save;
end

always @(*)
begin
    Deserializer_enable  = 0;
    data_valid           = 0;
    parity_check_enable  = 0;
    data_sampler_enable  = 0;
    start_check_enable   = 0;
    stop_check_enable    = 0;
    edge_bit_enable      = 0;
    shift_enable         = 0;

    case (current_state)
    
    idle_state:
    begin
        if (RX_IN == 0)
        begin
            next_state = start_state;
            edge_bit_enable     = 1;
            data_sampler_enable = 1;
            start_check_enable  = 1;
        end
        else 
        begin
            next_state = idle_state;           
        end
    end

    start_state:
    begin
        if (start_glitch)
        begin
            next_state = idle_state;
        end
        else if (edge_count == prescale - 1)
        begin
            next_state = data_state;
            edge_bit_enable     = 1;
            parity_check_enable = 1;
            data_sampler_enable = 1;
            shift_enable        = 0;  // No shift in start_state
        end
        else
        begin
            next_state = start_state;
            edge_bit_enable     = 1;
            data_sampler_enable = 1;
            start_check_enable  = 1;
        end
    end

    data_state:
    begin
        if (bit_count <= 8)  // Include bit_count == 8 for MSB shift
        begin
            next_state = data_state;
            edge_bit_enable     = 1;
            parity_check_enable = 1;
            data_sampler_enable = 1;
            shift_enable        = 1;
        end
        else if (bit_count == 9 && edge_count == prescale - 1)
        begin
            if (parity_enable_save == 0)
            begin
                next_state = stop_state;
                stop_check_enable   = 1;
                edge_bit_enable     = 1;
                Deserializer_enable = 1;
                parity_check_enable = 0;
                data_valid          = 0;
                data_sampler_enable = 1;
            end
            else
            begin
                next_state = parity_state;
                edge_bit_enable     = 1;
                parity_check_enable = 1;
                data_valid          = 0;
                data_sampler_enable = 1;
            end
        end
        else
        begin
            next_state = data_state;
            edge_bit_enable     = 1;
            parity_check_enable = 1;
            data_sampler_enable = 1;
            shift_enable        = 1;
        end
    end

    parity_state:
    begin
        if (parity_error)
            next_state = idle_state;
        else if (edge_count == prescale - 1)
        begin
            next_state = stop_state;
            stop_check_enable   = 1;
            edge_bit_enable     = 1;
            Deserializer_enable = 1;
            data_sampler_enable = 1;
            data_valid          = 0;
        end
        else
        begin
            next_state = parity_state;
            edge_bit_enable     = 1;
            parity_check_enable = 1;
            data_sampler_enable = 1;
        end          
    end

    stop_state:
    begin
        if (edge_count == prescale - 1)
        begin
            if (!stop_error)
            begin
                next_state = idle_state;
                Deserializer_enable = 1;
                data_valid          = 1;
            end
            else
            begin
                next_state = idle_state;
                data_valid = 0;
            end
        end
        else
        begin
            next_state = stop_state;
            stop_check_enable   = 1;
            edge_bit_enable     = 1;
            Deserializer_enable = 1;
            data_sampler_enable = 1;
        end
    end
    endcase
end
endmodule