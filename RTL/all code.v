module FSM
(
    input asy_reset,
    input clk_based_on_prescale,        // clk of the rx
    input RX_IN,
    input parity_enable,                // signal recieved out of the rx block
    input parity_error,                 // parity check
    input start_glitch,                 // start check
    input stop_error,                   // stop check
    input [3:0] edge_count,             // edge bit counter
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



//////////////////////////////////////////////////////////////////////////

module parity_check 
(
    input             asy_reset,
    input  wire       clk_based_on_prescale,
    input  wire       parity_type,          // 0 = even parity, 1 = odd parity
    input  wire       sampled_data,
    input  wire       parity_check_enable,
    input             sampled_data_valid,
    output reg        parity_error
);

    reg [3:0] counter;
    reg XORed_data;
    reg parity_bit;

    always @(posedge clk_based_on_prescale or negedge asy_reset) 
    begin
        if (!asy_reset)
        begin
            counter <= 0;
            parity_bit <=0;
            XORed_data   <= 0;
            parity_error <= 0;
        end
        if (parity_check_enable && sampled_data_valid) 
        begin
            counter <= counter + 1;

            if (counter < 8)
            begin
                XORed_data <= XORed_data ^ sampled_data;
            end 

            else if (counter == 8) 
            begin
                parity_bit <= sampled_data;

                case (parity_type)
                    1'b0: parity_error <= (XORed_data != parity_bit); // Even parity
                    1'b1: parity_error <= (XORed_data == parity_bit); // Odd parity
                endcase

                counter     <= 0;
                XORed_data  <= 0;
            end
        end 
        else 
        begin
            counter      <= 0;
            XORed_data   <= 0;
            parity_error <= 0;
        end
    end

endmodule






///////////////////////////////////////////////////////



module Deserializer (
    input  wire       clk_based_on_prescale,
    input  wire       Deserializer_enable,
    input  wire       sampled_data,        
    input  wire       sampled_data_valid, 
    input             asy_reset, 
    output reg [7:0]  parallel_data
);

reg [7:0] collected_data;

always @(posedge clk_based_on_prescale or negedge asy_reset) 
begin
    if (!asy_reset)
    begin
        collected_data <= 0;
        parallel_data  <= 0;
    end
    else if (sampled_data_valid) 
    begin
        collected_data <= {sampled_data, collected_data[7:1]};
    end
    else if(Deserializer_enable)
    begin
        parallel_data <= collected_data; // the FSM will send a signal to allow the deser. to send the data to the output associated with a valid_data signal  
    end
end

endmodule



///////////////////////////////////////////////////////////




module Edge_Bit_Counter
(
    input asy_reset,
    input RX_IN,
    input edge_bit_enable,
    input clk_based_on_prescale,
    output reg [3:0] edge_count,
    output reg [4:0] bit_count
);

reg internal_enable;

always@(posedge clk_based_on_prescale or edge_bit_enable or negedge asy_reset)
begin
    if(!asy_reset)
    begin
        bit_count      <=0;
        edge_count     <=0;
        internal_enable<=0;
    end
    else if(edge_bit_enable)
    begin
        internal_enable<=1;
        bit_count<=0;       // in the start state this will happen  
    end
    else if(internal_enable)
    begin
    edge_count++;           // and in the next clk cycle the edges and the bits will start to be calculated  
        if(edge_count==4'b0111)
        begin
            edge_count<=0;
            bit_count++;    // so when bit_count reach 8 then the data bits will be finished
        end

    end

end

endmodule




////////////////////////////////////////////////////////////////




module Data_Sampler (
    input             asy_reset,
    input  wire [5:0] prescale,
    input  wire       RX_IN,
    input  wire       clk_based_on_prescale,
    input  wire       data_sampler_enable,
    input  wire [5:0] edge_count,
    output wire       sampled_data,
    output reg        sampled_data_valid   
);

reg [2:0] data_majority;

always @(posedge clk_based_on_prescale or negedge asy_reset) 
begin
    sampled_data_valid <= 1'b0;  
     if(!asy_reset)
     begin
        sampled_data_valid <= 0;
        data_majority      <= 0;
        sampled_data       <= 0;
     end

    else if (data_sampler_enable) 
    begin
        case (prescale)
        6'd8: begin
            if (edge_count==3 || edge_count==4 || edge_count==5) 
            begin
                data_majority <= {data_majority[1:0], RX_IN};
                if (edge_count==5)
                    sampled_data_valid <= 1'b1;    
            end
        end

        6'd16: begin
            if (edge_count==7 || edge_count==8 || edge_count==9) 
            begin
                data_majority <= {data_majority[1:0], RX_IN};
                if (edge_count==9)
                    sampled_data_valid <= 1'b1;
            end
        end

        6'd32: begin
            if (edge_count==15 || edge_count==16 || edge_count==17) 
            begin
                data_majority <= {data_majority[1:0], RX_IN};
                if (edge_count==17)
                    sampled_data_valid <= 1'b1;
            end
        end
        endcase
    end
end

assign sampled_data = (data_majority[0] + data_majority[1] + data_majority[2] >= 2);

endmodule



////////////////////////////////////////////////////




module start_check 
(
    input  wire       clk_based_on_prescale,
    input  wire       sampled_data,
    input  wire       start_check_enable,
    input             asy_reset,
    input             sampled_data_valid,
    output reg        start_glitch
);


always@(posedge clk_based_on_prescale or negedge asy_reset)
begin
    if(!asy_reset)
        start_glitch<=0;
    else if(start_check_enable && sampled_data_valid)
    begin
        case (sampled_data)
            1'b0: start_glitch <= 1'b0; // start bit valid
            1'b1: start_glitch <= 1'b1; // glitch detected
        endcase
    end
    else 
        start_glitch <= 1'b0; 
end




endmodule



//////////////////////////////////////////////////





module stop_check 
(
    input  wire       clk_based_on_prescale,
    input  wire       sampled_data,
    input  wire       stop_check_enable,
    input  wire       sampled_data_valid, 
    input             asy_reset,
    output reg        stop_error
);


always@(posedge clk_based_on_prescale or negedge asy_reset)
begin
    if(!asy_reset)
        stop_error<=0;
    else if(stop_check_enable && sampled_data_valid) 

    begin
        case (sampled_data)
            1'b1: stop_error <= 1'b0; // stop bit valid
            1'b0: stop_error <= 1'b1; // error detected
        endcase
    end
    else 
        stop_error <= 1'b0; 
end




endmodule