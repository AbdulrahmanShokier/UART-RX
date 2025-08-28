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