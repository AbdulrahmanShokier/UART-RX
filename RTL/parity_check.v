module parity_check 
(
    input             asy_reset,
    input  wire       clk_based_on_prescale,
    input  wire       parity_type,          // 0 = even parity, 1 = odd parity
    input  wire       sampled_data,
    input  wire       parity_check_enable,
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
