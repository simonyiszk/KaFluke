module debouncer #(
    parameter clk_freq = 12_000_000,
    parameter filter_freq = 10
)
(
    input wire clk,
    input wire areset_n,
    input wire raw_signal_i,
    output reg filtered_signal_o
);

    reg input_ff_1;
    reg input_ff_2;
    reg input_filtered;
    localparam filter_limit = (clk_freq / filter_freq);
    localparam filter_width = $clog2(filter_limit);
    reg [filter_width-1:0] filter_cntr;


    always @(posedge clk, negedge areset_n)
    begin
        if (!areset_n) begin
            input_ff_1 <= 1'b0;
            input_ff_2 <= 1'b0;
            input_filtered <= 1'b0;
        end else begin
            input_ff_1 <= raw_signal_i;
            input_ff_2 <= input_ff_1;
            input_filtered <= input_ff_2;
        end;
    end;

    always @(posedge clk, negedge areset_n)
    begin
        if (!areset_n) begin
            filter_cntr <= filter_width'b0;
            filtered_signal_o <= 1'b0;
        end else begin
            if (filter_cntr < filter_limit)
                filter_cntr <= filter_cntr + 1'b1;
            else
                filtered_signal_o <= input_filtered;
            if (input_filtered != input_ff_2)
                filter_cntr <= 0;
        end;
    end;

endmodule
