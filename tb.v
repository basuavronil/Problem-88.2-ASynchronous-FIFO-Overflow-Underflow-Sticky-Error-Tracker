`timescale 1ns / 1ps

module tb_async_fifo_error_tracker;

    // Write Domain Inputs
    reg wr_clk;
    reg wr_rst_n;
    reg full;
    reg wr_en;

    // Read Domain Inputs
    reg rd_clk;
    reg rd_rst_n;
    reg empty;
    reg rd_en;

    // Software Control Input
    reg sw_clr_err;

    // Outputs
    wire overflow_err;
    wire underflow_err;
    wire sticky_error;

    // Unit Under Test (UUT)
    async_fifo_error_tracker uut (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .full(full),
        .wr_en(wr_en),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .empty(empty),
        .rd_en(rd_en),
        .sw_clr_err(sw_clr_err),
        .overflow_err(overflow_err),
        .underflow_err(underflow_err),
        .sticky_error(sticky_error)
    );

    // Independent Clock Generators
    // Write Clock: 100 MHz (10ns period)
    always #5 wr_clk = ~wr_clk;

    // Read Clock: ~66.6 MHz (15ns period) to simulate asynchronous domains
    always #7.5 rd_clk = ~rd_clk;

    initial begin
        // 1. Setup VCD waveform dumping
        $dumpfile("async_fifo_error_tracker.vcd");
        $dumpvars(0, tb_async_fifo_error_tracker);

        // 2. Setup real-time console signal monitoring
        $monitor("Time=%0tns | wr_rst_n=%b rd_rst_n=%b | wr_en=%b full=%b ovf=%b | rd_en=%b empty=%b unf=%b | sw_clr=%b | sticky_err=%b",
                 $time, wr_rst_n, rd_rst_n, wr_en, full, overflow_err, rd_en, empty, underflow_err, sw_clr_err, sticky_error);

        // Initialize Inputs
        wr_clk     = 0;
        wr_rst_n   = 0;
        full       = 0;
        wr_en      = 0;

        rd_clk     = 0;
        rd_rst_n   = 0;
        empty      = 0;
        rd_en      = 0;

        sw_clr_err = 0;

        // Apply Resets
        #20;
        wr_rst_n = 1;
        rd_rst_n = 1;
        #15;

        // Scenario 1: Normal operations (No errors)
        @(posedge wr_clk); full = 0; wr_en = 1;
        @(posedge wr_clk); wr_en = 0;

        @(posedge rd_clk); empty = 0; rd_en = 1;
        @(posedge rd_clk); rd_en = 0;
        #20;

        // Scenario 2: Trigger Overflow in Write Domain (Write while full)
        @(posedge wr_clk); full = 1; wr_en = 1;
        @(posedge wr_clk); wr_en = 0; full = 0;
        #30; // Verify sticky_error stays high across clock domains

        // Scenario 3: Software Clear
        @(posedge wr_clk); sw_clr_err = 1;
        @(posedge wr_clk); sw_clr_err = 0;
        #30;

        // Scenario 4: Trigger Underflow in Read Domain (Read while empty)
        @(posedge rd_clk); empty = 1; rd_en = 1;
        @(posedge rd_clk); rd_en = 0; empty = 0;
        #30; // Verify sticky_error latches again

        // Scenario 5: Software Clear again
        @(posedge rd_clk); sw_clr_err = 1;
        @(posedge rd_clk); sw_clr_err = 0;
        #30;

        $finish;
    end

endmodule
