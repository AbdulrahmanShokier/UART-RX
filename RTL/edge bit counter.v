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




