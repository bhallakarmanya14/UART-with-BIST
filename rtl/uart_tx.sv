module uart_tx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        tick,
    input  logic        tx_start,
    input  logic [7:0]  tx_data,
    output logic        tx,
    output logic        tx_busy
);

    typedef enum logic [1:0] {
        S_IDLE,
        S_START,
        S_DATA,
        S_STOP
    } state_t;

    state_t             state, state_next;
    logic [3:0]         tick_cnt, tick_cnt_next;
    logic [2:0]         bit_idx, bit_idx_next;
    logic [7:0]         data_reg, data_reg_next;
    logic               tx_next;
    logic               tx_busy_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            tick_cnt <= 4'd0;
            bit_idx  <= 3'd0;
            data_reg <= 8'd0;
            tx       <= 1'b1;
            tx_busy  <= 1'b0;
        end else begin
            state    <= state_next;
            tick_cnt <= tick_cnt_next;
            bit_idx  <= bit_idx_next;
            data_reg <= data_reg_next;
            tx       <= tx_next;
            tx_busy  <= tx_busy_next;
        end
    end

    always_comb begin
        state_next    = state;
        tick_cnt_next = tick_cnt;
        bit_idx_next  = bit_idx;
        data_reg_next = data_reg;
        tx_next       = tx;
        tx_busy_next  = tx_busy;

        case (state)
            S_IDLE: begin
                tx_next      = 1'b1;
                tx_busy_next = 1'b0;
                if (tx_start) begin
                    state_next    = S_START;
                    tick_cnt_next = 4'd0;
                    data_reg_next = tx_data;
                    tx_busy_next  = 1'b1;
                end
            end

            S_START: begin
                tx_next = 1'b0;
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        state_next    = S_DATA;
                        tick_cnt_next = 4'd0;
                        bit_idx_next  = 3'd0;
                    end else begin
                        tick_cnt_next = tick_cnt + 4'd1;
                    end
                end
            end

            S_DATA: begin
                tx_next = data_reg[bit_idx];
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        tick_cnt_next = 4'd0;
                        if (bit_idx == 3'd7) begin
                            state_next = S_STOP;
                        end else begin
                            bit_idx_next = bit_idx + 3'd1;
                        end
                    end else begin
                        tick_cnt_next = tick_cnt + 4'd1;
                    end
                end
            end

            S_STOP: begin
                tx_next = 1'b1;
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        state_next = S_IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt + 4'd1;
                    end
                end
            end

            default: begin
                state_next = S_IDLE;
            end
        endcase
    end

endmodule
