# Single-Cycle MIPS32 Processor (Verilog)

A synthesizable single-cycle implementation of the classic MIPS32 datapath, built from scratch in Verilog for a digital design / computer architecture project.

## Features
- Full single-cycle datapath: PC, instruction memory, register file, ALU, data memory, and control unit
- Supports core instruction types: R-type (add, sub, and, or, slt), load/store (lw, sw), branch (beq), and jump (j)
- Modular design with separate `alu`, `alu_control`, `control_unit`, `register_file`, `instr_memory`, and `data_memory` modules
- Self-checking testbench that verifies a lw → lw → add → sw sequence end-to-end, checking both register file and data memory writes
- Verified in Vivado behavioral simulation

## Structure
- `mips_top.v` — top-level datapath wiring
- `alu.v`, `alu_control.v` — arithmetic/logic unit and its control decoding
- `control_unit.v` — main instruction decoder
- `register_file.v` — 32x32-bit register file
- `instr_memory.v`, `data_memory.v` — instruction and data memories
- `testbench.v` — simulation testbench
- `program.hex` — sample machine code program for simulation

## Simulation
Run in Vivado (or any Verilog simulator) with `program.hex` loaded via `$readmemh`. Expected output:
```
t0 (reg8)  = 5
t1 (reg9)  = 10
t2 (reg10) = 15
mem[2] (byte addr 8) = 15
PASS: single-cycle datapath correct
```
