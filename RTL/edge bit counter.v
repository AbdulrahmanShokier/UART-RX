module Edge_Bit_Counter
(
    input RX_IN,
    input enable,
    input clk_based_on_prescale,
    output reg [3:0] edge_count,
    output reg [4:0] bit_count
);

reg internal_enable;

always@(posedge clk_based_on_prescale or enable)
begin
    if(enable)
    begin
        internal_enable=1;
        bit_count=0;
    end
    else if(internal_enable)
    begin
    edge_count++;
        if(edge_count==4'b0111)
        begin
            edge_count<=0;
            bit_count++;
        end

    end

end

endmodule




