module Deserializer (
    input  wire       clk_based_on_prescale,
    input  wire       Deserializer_enable,
    input  wire       shift_enable,        // New: from FSM, active in data_state
    input  wire       sampled_data,        
    input  wire       sampled_data_valid, 
    input  wire       asy_reset, 
    output reg [7:0]  parallel_data
);

    reg [7:0] collected_data;
    reg [3:0] counter;

    always @(posedge clk_based_on_prescale or negedge asy_reset) 
    begin
        if (!asy_reset)
        begin
            collected_data <= 0;
            parallel_data  <= 0;
            counter        <= 0;
        end
        else if (sampled_data_valid && shift_enable) 
        begin
            counter <= counter + 1;
            if (counter < 8)  // Shift only 8 data bits
            begin
                collected_data <= {sampled_data, collected_data[7:1]};
            end
            else if (counter == 8)
            begin
                counter <= 0;  // Reset after 8 shifts
            end
        end
        else if (Deserializer_enable)
        begin
            parallel_data <= collected_data;
            counter       <= 0;
        end
        else if (!shift_enable)
        begin
            counter <= 0;  // Reset counter when not in data_state
        end
    end
endmodule