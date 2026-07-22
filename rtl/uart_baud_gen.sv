module uart_baud_gen #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  logic        clk,
    input  logic        rst_n,
    output logic        tick
);

    localparam integer DIVISOR = CLK_FREQ / (BAUD_RATE * 16);
    localparam integer CNT_W  = $clog2(DIVISOR);

    logic [CNT_W-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            tick    <= 1'b0;
        end else begin
            if (counter == DIVISOR - 1) begin
                counter <= '0;
                tick    <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                tick    <= 1'b0;
            end
        end
    end

endmodule
