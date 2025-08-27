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
