module Edge_Bit_Counter
(
    input  wire       asy_reset,
    input  wire       edge_bit_enable,
    input  wire       clk_based_on_prescale,
    input  wire [5:0] prescale,
    output reg  [5:0] edge_count,
    output reg  [4:0] bit_count
);

reg internal_enable;

always @(posedge clk_based_on_prescale or negedge asy_reset)
begin
    if (!asy_reset)
    begin
        bit_count      <= 0;
        edge_count     <= 0;
        internal_enable <= 0;
    end
    else
    begin
        if (edge_bit_enable)
        begin
            internal_enable <= 1;
            bit_count      <= 0;
            edge_count     <= 0;
        end
        else if (internal_enable)
        begin
            edge_count <= edge_count + 1;
            if (edge_count == prescale - 1)
            begin
                edge_count <= 0;
                bit_count  <= bit_count + 1;
            end
        end
    end
end
endmodule