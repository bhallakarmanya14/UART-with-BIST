# UART Controller with Built-In Self-Test (BIST)

SystemVerilog UART controller (8N1) with an integrated BIST engine for power-on self-test, targeting Xilinx Vivado.

## Architecture

```
uart_bist (top)
├── uart_baud_gen   — 16x oversampling baud rate generator
├── uart_tx         — 4-state TX FSM (IDLE → START → DATA → STOP)
├── uart_rx         — 4-state RX FSM with 2-FF metastability sync
├── bist_engine     — 6-state BIST FSM for self-test
└── mux             — bist_en selects between BIST and external data
```

## How It Works

1. **BIST runs at power-on** — sends test patterns through TX, loops back to RX, compares received data
2. **If BIST passes** — switches to normal UART operation
3. **If BIST fails** — flags the error via `bist_pass = 0`

## File Structure

```
rtl/
├── uart_baud_gen.sv    Shared baud rate generator
├── uart_tx.sv          UART transmitter
├── uart_rx.sv          UART receiver
├── bist_engine.sv      BIST FSM
└── uart_bist.sv        Top module (UART + BIST)
tb/
└── uart_bist_multi.sv  Testbench: BIST + N sequential transfers
```

## Simulation

- **Tool**: Vivado Behavioral Simulation
- **Parameters**: `CLK_FREQ=32`, `BAUD_RATE=1` (fast sim timing)
- **Run**: Set `uart_bist_multi` as sim top → `run all`

### Expected Output
```
BIST PASS
Frame 0: PASS TX=a0 RX=a0
Frame 1: PASS TX=a1 RX=a1
Frame 2: PASS TX=a2 RX=a2
3/3 frames passed
```

## Parameters

| Parameter | Simulation | Synthesis |
|-----------|-----------|-----------|
| CLK_FREQ  | 32        | 50000000  |
| BAUD_RATE | 1         | 115200    |
| NUM_TESTS | 1         | 4         |
