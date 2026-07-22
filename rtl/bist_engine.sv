module bist_engine #(
    parameter NUM_TESTS = 4
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        bist_start,

    output reg         tx_start,
    output reg  [7:0]  tx_data,
    input  wire        tx_busy,

    input  wire  [7:0] rx_data,
    input  wire        rx_valid,

    output reg         bist_done,
    output reg         bist_pass
);

    localparam [2:0] S_IDLE    = 3'd0,
                     S_SEND    = 3'd1,
                     S_WAIT_TX = 3'd2,
                     S_WAIT_RX = 3'd3,
                     S_CHECK   = 3'd4,
                     S_DONE    = 3'd5;

    reg [2:0]  state;
    reg [7:0]  pattern;
    reg [7:0]  expected;
    reg [3:0]  test_cnt;
    reg        all_pass;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            pattern   <= 8'd0;
            expected  <= 8'd0;
            test_cnt  <= 4'd0;
            all_pass  <= 1'b1;
            tx_start  <= 1'b0;
            tx_data   <= 8'd0;
            bist_done <= 1'b0;
            bist_pass <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx_start <= 1'b0;
                    if (bist_start) begin
                        state     <= S_SEND;
                        pattern   <= 8'd0;
                        test_cnt  <= 4'd0;
                        all_pass  <= 1'b1;
                        bist_done <= 1'b0;
                        bist_pass <= 1'b0;
                    end
                end

                S_SEND: begin
                    tx_start <= 1'b1;
                    tx_data  <= pattern;
                    expected <= pattern;
                    state    <= S_WAIT_TX;
                end

                S_WAIT_TX: begin
                    tx_start <= 1'b0;
                    if (tx_busy)
                        state <= S_WAIT_RX;
                end

                S_WAIT_RX: begin
                    if (rx_valid)
                        state <= S_CHECK;
                end

                S_CHECK: begin
                    if (rx_data != expected)
                        all_pass <= 1'b0;
                    test_cnt <= test_cnt + 4'd1;
                    if (test_cnt == NUM_TESTS - 1) begin
                        state     <= S_DONE;
                        bist_done <= 1'b1;
                        if (rx_data != expected)
                            bist_pass <= 1'b0;
                        else
                            bist_pass <= all_pass;
                    end else begin
                        pattern <= pattern + 8'd1;
                        state   <= S_SEND;
                    end
                end

                S_DONE: begin
                    bist_done <= 1'b1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
