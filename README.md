# MIPS32 Processor in Verilog

A MIPS32 processor built from scratch in Verilog, verified in Xilinx Vivado.
Includes two independent implementations of the same instruction set —
single-cycle and multi-cycle — each simulated and passing a common test
program.

---

## What it does

Executes the core MIPS32 instruction set:

| Type | Instructions |
|---|---|
| Arithmetic/Logic | `add`, `sub`, `and`, `or`, `slt` |
| Immediate | `addi` |
| Memory | `lw`, `sw` |
| Control flow | `beq`, `j` |

---

## Folder structure

single_cycle/ -> combinational datapath, 1 instruction per clock cycle
multi_cycle/ -> FSM-based datapath, instructions take multiple cycles


Each folder is self-contained: datapath modules, testbench, and test
program (`program.hex`).

---

## How each version works

**Single-cycle** — every instruction fetches, decodes, executes, accesses
memory, and writes back in one clock edge. Simple, but the clock period
is limited by the slowest instruction.

**Multi-cycle** — instructions move through 5 states (Fetch → Decode →
Execute → Memory → Writeback), only using the stages they actually need.
Uses a shared instruction/data memory and staging registers between
states. This is the natural stepping stone toward a pipelined design.

---

## Running the simulation (Vivado)

1. Add the datapath `.v` files as **Design Sources**
2. Add the testbench and `program.hex` as **Simulation Sources**
3. Set the testbench as simulation top
4. Run Behavioral Simulation

## Sample result (multi-cycle)

t0 = 5, t1 = 5, t2 = 0 (beq correctly skipped an instruction)
t3 = 10, t4 = 0
mem[80] = 10
PASS: addi, beq, add, sub, sw all correct


---

## Roadmap

- [x] Single-cycle datapath
- [x] Multi-cycle datapath
- [ ] Pipelined datapath (hazard detection + forwarding)
