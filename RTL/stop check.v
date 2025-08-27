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