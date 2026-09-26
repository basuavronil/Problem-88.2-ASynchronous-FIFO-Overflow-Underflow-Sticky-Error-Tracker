module async_fifo_error_tracker (
    // Write Domain
    input  wire wr_clk,
    input  wire wr_rst_n,
    input  wire full,
    input  wire wr_en,
    
    // Read Domain
    input  wire rd_clk,
    input  wire rd_rst_n,
    input  wire empty,
    input  wire rd_en,

    // Software Clear
    input  wire sw_clr_err,

    // Outputs
    output wire overflow_err,
    output wire underflow_err,
    output reg  sticky_error
);

    // 1. Detect immediate errors in their respective domains
    assign overflow_err  = wr_en & full;
    assign underflow_err = rd_en & empty;

    // 2. Latch Sticky Overflow in Write Clock Domain
    reg sticky_overflow;
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            sticky_overflow <= 1'b0;
        else if (sw_clr_err)
            sticky_overflow <= 1'b0;
        else if (overflow_err)
            sticky_overflow <= 1'b1;
    end

    // 3. Latch Sticky Underflow in Read Clock Domain
    reg sticky_underflow;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            sticky_underflow <= 1'b0;
        else if (sw_clr_err)
            sticky_underflow <= 1'b0;
        else if (underflow_err)
            sticky_underflow <= 1'b1;
    end

    // 4. Combine sticky status
    always @(*) begin
        sticky_error = sticky_overflow | sticky_underflow;
    end

endmodule
