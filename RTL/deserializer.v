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
