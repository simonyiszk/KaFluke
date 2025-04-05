module tdr_top
(
    input wire btn_0_i,
    input wire btn_1_i,
    input wire clk,
    output wire led_1_o,
    output wire led_2_o,
    output wire pulse_o,
    output wire rled,
    output wire bled,
    output wire gled
);

    localparam clk_freq = 12_000_000;
    localparam debounce_freq = 10;
    reg areset_n;
    wire btn_0_filt;
    reg btn_0_filt_ff;
    wire btn_1_filt;
    reg btn_1_filt_ff;
    reg led_1_state;
    reg led_2_state;
    reg [23:0] sec_cntr;
    wire clk_fast;
    wire clk_fast_unbuffered;
    wire areset_fast_n;
    wire clk_feedback;
    wire trigger;
    reg trigger_fast_ff1;
    reg trigger_fast_ff2;
    reg trigger_fast_ff3;
    reg pulse;

    always @(posedge clk)
    begin
        areset_n <= 1'b1;
    end;

    debouncer #(
        .clk_freq(clk_freq),
        .filter_freq(debounce_freq)
    ) debounce_btn0 (
        .clk(clk),
        .areset_n(areset_n),
        .raw_signal_i(btn_0_i),
        .filtered_signal_o(btn_0_filt)
    );

    always @(posedge clk, negedge areset_n)
    begin
        if (!areset_n) begin
            btn_0_filt_ff <= 1'b0;
            btn_1_filt_ff <= 1'b0;
        end else begin
            btn_0_filt_ff <= btn_0_filt;
            btn_1_filt_ff <= btn_1_filt;
        end;
    end;

    always @(posedge clk, negedge areset_n)
    begin
        if (!areset_n) begin
            led_1_state <= 1'b0;
            led_2_state <= 1'b0;
        end else begin
            if (btn_0_filt & ~btn_0_filt_ff)
                led_1_state <= ~led_1_state;
            if (btn_1_filt & ~btn_1_filt_ff)
                led_2_state <= ~led_2_state;
        end;
    end;
    assign led_1_o = led_1_state;
    assign led_2_o = led_2_state;

    debouncer #(
        .clk_freq(clk_freq),
        .filter_freq(debounce_freq)
    ) debounce_btn1 (
        .clk(clk),
        .areset_n(areset_n),
        .raw_signal_i(btn_1_i),
        .filtered_signal_o(btn_1_filt)
    );

    PLLE2_BASE #(
        .BANDWIDTH("OPTIMIZED"), // OPTIMIZED, HIGH, LOW
        .CLKFBOUT_MULT(20),  // Multiply value for all CLKOUT (2-64)
        .CLKFBOUT_PHASE("0.0"),  // Phase offset in degrees of CLKFB, (-360-360)
        .CLKIN1_PERIOD("83.333"),  // Input clock period in ns to ps resolution
        .CLKOUT0_DIVIDE(1),
        .CLKOUT0_DUTY_CYCLE("0.5"),
        .CLKOUT0_PHASE("0.0"),
        .DIVCLK_DIVIDE(1),      // Master division value , (1-56)
        .REF_JITTER1("0.0"),    // Reference input jitter in UI (0.000-0.999)
        .STARTUP_WAIT("FALSE")  // Delayu DONE until PLL Locks, ("TRUE"/"FALSE")
    ) genclock(
        .CLKOUT0(clk_fast_unbuffered),
        .CLKFBOUT(clk_feedback), // 1-bit output, feedback clock
        .CLKIN1(clk),
        .PWRDWN(1'b0),
        .RST(1'b0),
        .LOCKED(areset_fast_n),
        .CLKFBIN(clk_feedback)    // 1-bit input, feedback clock
    );

    BUFG bufg(
        .I(clk_fast_unbuffered),
        .O(clk_fast)
    );

    always @(posedge clk, negedge areset_n)
    begin
        if (!areset_n)
            sec_cntr <= 24'b0;
        else
            if (led_1_state == 1'b1)
                if (sec_cntr < clk_freq)
                    sec_cntr <= sec_cntr + 24'b1;
                else
                    sec_cntr <= 24'b0;
    end;

    assign trigger = ((sec_cntr == 24'b0) | (btn_1_filt & ~btn_1_filt_ff)) ? 1'b1 : 1'b0;
    always @(posedge clk_fast, negedge areset_fast_n)
    begin
        if (!areset_fast_n) begin
            pulse <= 1'b0;
            trigger_fast_ff1 <= 1'b0;
            trigger_fast_ff2 <= 1'b0;
            trigger_fast_ff3 <= 1'b0;
        end else begin
            trigger_fast_ff1 <= trigger;
            trigger_fast_ff2 <= trigger_fast_ff1;
            trigger_fast_ff3 <= trigger_fast_ff2;

            if (trigger_fast_ff2 & ~trigger_fast_ff3)
                pulse <= 1'b1;
            else
                pulse <= 1'b0;
        end;
    end;
    assign pulse_o = pulse;

    assign rled = 1'b1;
    assign bled = 1'b1;
    assign gled = 1'b1;

endmodule
