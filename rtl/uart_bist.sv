// UART Top with Integrated BIST (8N1)
// Uses the same uart_tx, uart_rx, uart_baud_gen as uart_top
// bist_en muxes between external user data and BIST-generated data

module uart_bist #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200,
    parameter NUM_TESTS = 4
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        tx_start_ext,
    input  logic [7:0]  tx_data_ext,
    output logic        tx_busy,

    output logic        tx,
    input  logic        rx,

    output logic [7:0]  rx_data,
    output logic        rx_valid,

    input  logic        bist_en,
    input  logic        bist_start,
    output logic        bist_done,
    output logic        bist_pass
);

    logic        tick;
    logic        bist_tx_start;
    logic [7:0]  bist_tx_data;

    logic        tx_start_mux;
    logic [7:0]  tx_data_mux;

    assign tx_start_mux = bist_en ? bist_tx_start : tx_start_ext;
    assign tx_data_mux  = bist_en ? bist_tx_data  : tx_data_ext;

    uart_baud_gen #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (tick)
    );

    uart_tx u_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick     (tick),
        .tx_start (tx_start_mux),
        .tx_data  (tx_data_mux),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );

    uart_rx u_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick     (tick),
        .rx       (rx),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    bist_engine #(
        .NUM_TESTS (NUM_TESTS)
    ) u_bist (
        .clk        (clk),
        .rst_n      (rst_n),
        .bist_start (bist_start),
        .tx_start   (bist_tx_start),
        .tx_data    (bist_tx_data),
        .tx_busy    (tx_busy),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .bist_done  (bist_done),
        .bist_pass  (bist_pass)
    );

endmodule
