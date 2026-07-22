`timescale 1ns / 1ps

module uart_bist_tb;

    parameter CLK_FREQ  = 32;
    parameter BAUD_RATE = 1;
    parameter NUM_TESTS = 1;

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

    // Hard simulation limit
    initial begin
        #1000;
        $display("SIM TIMEOUT");
        $finish;
    end

    initial begin
        rst_n        = 0;
        tx_start_ext = 0;
        tx_data_ext  = 8'h00;
        bist_en      = 1;
        bist_start   = 0;

        repeat (10) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        // Phase 1 - BIST verifies the UART circuit
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

        // Phase 2 - Normal transfer after BIST approval
        bist_en = 0;
        @(posedge clk);
        tx_data_ext  = 8'hA5;
        tx_start_ext = 1;
        @(posedge clk);
        tx_start_ext = 0;

        wait (rx_valid == 1 || $time > 900);

        if (rx_valid) begin
            if (rx_data == 8'hA5)
                $display("PASS TX=A5 RX=%h", rx_data);
            else
                $display("FAIL TX=A5 RX=%h", rx_data);
        end else begin
            $display("FAIL TIMEOUT");
        end

        repeat (5) @(posedge clk);
        $finish;
    end

endmodule
