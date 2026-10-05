# Chapter 2 – Lab 2: AND Gate Synthesis (Yosys + Sky130)

Synthesize `rtl/and_gate.sv` into a Sky130 HD gate-level netlist.

**Tools:** Yosys 0.65+71, `sky130_fd_sc_hd__tt_025C_1v80.lib`

## Run

Set `LIB` at the top of `run_synth.sh` to the local path of the Sky130 HD liberty file, then:

    ./run_synth.sh

## Files

- `rtl/and_gate.sv` – RTL
- `run_synth.sh` – synthesis script
- `netlist/and_gate_net.v` – gate-level netlist
- `reports/stat.txt` – cell usage and area