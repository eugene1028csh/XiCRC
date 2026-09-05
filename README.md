# Xicrc CRC Accelerator

Standalone Verilog implementation of the ChampionCHIP Xicrc CRC unit.

Supports:

- `CRCB` → process 8 bits
- `CRCH` → process 16 bits
- `CRCW` → process 32 bits
- 16-bit CRC result
- CPU-facing wrapper for extension decoding and writeback

The current implementation uses an MSB-first CRC update with polynomial `0x1021`.

## Structure

```text
rtl/
├── xicrc_exec.v
└── xicrc_accelerator_unit.v

tb/
├── xicrc_exec_tb.v
└── xicrc_accelerator_unit_tb.v

## Run

```text
Run CRC Engine + Testbench"
iverilog -g2012 -o exec_sim \
    rtl/xicrc_exec.v \
    tb/xicrc_exec_tb.v
and
vvp exec_sim
Expected result:
ALL XICRC EXEC TESTS PASSED

Run CPU Wrapper TB:

iverilog -g2012 -o wrapper_sim \
    rtl/xicrc_exec.v \
    rtl/xicrc_accelerator_unit.v \
    tb/xicrc_accelerator_unit_tb.v
and 
vvp wrapper_sim

Expected result:
ALL XICRC WRAPPER TESTS PASSED