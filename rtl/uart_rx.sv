module uart_rx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        tick,
    input  logic        rx,
    output logic [7:0]  rx_data,
    output logic        rx_valid
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
    logic               rx_valid_next;
    logic [7:0]         rx_data_next;

    logic               rx_sync_0, rx_sync_1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end else begin
            rx_sync_0 <= rx;
            rx_sync_1 <= rx_sync_0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            tick_cnt <= 4'd0;
            bit_idx  <= 3'd0;
            data_reg <= 8'd0;
            rx_data  <= 8'd0;
            rx_valid <= 1'b0;
        end else begin
            state    <= state_next;
            tick_cnt <= tick_cnt_next;
            bit_idx  <= bit_idx_next;
            data_reg <= data_reg_next;
            rx_data  <= rx_data_next;
            rx_valid <= rx_valid_next;
        end
    end

    always_comb begin
        state_next    = state;
        tick_cnt_next = tick_cnt;
        bit_idx_next  = bit_idx;
        data_reg_next = data_reg;
        rx_data_next  = rx_data;
        rx_valid_next = 1'b0;

        case (state)
            S_IDLE: begin
                if (~rx_sync_1) begin
                    state_next    = S_START;
                    tick_cnt_next = 4'd0;
                end
            end

            S_START: begin
                if (tick) begin
                    if (tick_cnt == 4'd7) begin
                        if (~rx_sync_1) begin
                            state_next    = S_DATA;
                            tick_cnt_next = 4'd0;
                            bit_idx_next  = 3'd0;
                        end else begin
                            state_next = S_IDLE;
                        end
                    end else begin
                        tick_cnt_next = tick_cnt + 4'd1;
                    end
                end
            end

            S_DATA: begin
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        tick_cnt_next = 4'd0;
                        data_reg_next = data_reg;
                        data_reg_next[bit_idx] = rx_sync_1;
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
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        state_next    = S_IDLE;
                        if (rx_sync_1) begin
                            rx_data_next  = data_reg;
                            rx_valid_next = 1'b1;
                        end
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
