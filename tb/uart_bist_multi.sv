`timescale 1ns / 1ps

module uart_bist_multi;

    // Change this to send more frames
    parameter NUM_FRAMES = 3;

    parameter CLK_FREQ   = 32;
    parameter BAUD_RATE  = 1;
    parameter NUM_TESTS  = 1;

    // One frame takes ~350 ns, total sim = (NUM_FRAMES + 1) * 400 + margin
    parameter SIM_LIMIT  = (NUM_FRAMES + 2) * 400;

    logic        clk;
    logic        rst_n;
    logic        tx_start_ext;
    logic [7:0]  tx_data_ext;
    logic        tx_busy;
    logic        tx;
    logic [7:0]  rx_data;
    logic        rx_valid;
    logic        bist_en;
    logic        bist_start;
    logic        bist_done;
    logic        bist_pass;

    uart_bist #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE),
        .NUM_TESTS (NUM_TESTS)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .tx_start_ext (tx_start_ext),
        .tx_data_ext  (tx_data_ext),
        .tx_busy      (tx_busy),
        .tx           (tx),
        .rx           (tx),
        .rx_data      (rx_data),
        .rx_valid     (rx_valid),
        .bist_en      (bist_en),
        .bist_start   (bist_start),
        .bist_done    (bist_done),
        .bist_pass    (bist_pass)
    );

    initial clk = 0;
    always #0.5 clk = ~clk;

    initial begin
        #(SIM_LIMIT);
        $display("SIM TIMEOUT at %0t", $time);
        $finish;
    end

    integer i          = 0;
    integer pass_count = 0;
    logic [7:0] tx_byte = 8'h00;

    initial begin
        rst_n        = 0;
        tx_start_ext = 0;
        tx_data_ext  = 8'h00;
        bist_en      = 1;
        bist_start   = 0;

        repeat (10) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        // Phase 1 - BIST power-on self-test
        @(posedge clk);
        bist_start = 1;
        @(posedge clk);
        bist_start = 0;

        wait (bist_done == 1 || $time > 500);

        if (!bist_done) begin
            $display("BIST TIMEOUT");
            $finish;
        end

        if (bist_pass)
            $display("BIST PASS");
        else begin
            $display("BIST FAIL");
            $finish;
        end

        repeat (10) @(posedge clk);
        bist_en = 0;

        // Phase 2 - Send NUM_FRAMES sequential transfers
        for (i = 0; i < NUM_FRAMES; i = i + 1) begin
            tx_byte = 8'hA0 + i[7:0];

            @(posedge clk);
            tx_data_ext  = tx_byte;
            tx_start_ext = 1;
            @(posedge clk);
            tx_start_ext = 0;

            // Wait for this frame to complete
            @(posedge rx_valid or posedge bist_done);
            @(posedge clk);

            if (rx_data == tx_byte) begin
                $display("Frame %0d: PASS TX=%h RX=%h", i, tx_byte, rx_data);
                pass_count = pass_count + 1;
            end else begin
                $display("Frame %0d: FAIL TX=%h RX=%h", i, tx_byte, rx_data);
            end

            repeat (10) @(posedge clk);
        end

        $display("%0d/%0d frames passed", pass_count, NUM_FRAMES);

        repeat (5) @(posedge clk);
        $finish;
    end

endmodule
