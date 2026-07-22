module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        tx_start,
    input  logic [7:0]  tx_data,
    output logic        tx,
    output logic        tx_busy,

    input  logic        rx,
    output logic [7:0]  rx_data,
    output logic        rx_valid
);

    logic tick;

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
        .tx_start (tx_start),
        .tx_data  (tx_data),
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

endmodule
