#!/usr/bin/env bash
# Synthesize rtl/and_gate.sv with Yosys + Sky130 HD (machine-specific LIB path below).
set -euo pipefail
cd "$(dirname "$0")"
LIB="/home/vu/eda/repos/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
[ -f "$LIB" ] || { echo "ERROR: LIB not found: $LIB"; exit 1; }
mkdir -p reports netlist
yosys -l reports/yosys.log -p "
  read_verilog -sv rtl/and_gate.sv
  synth -top and_gate -flatten
  check -assert
  abc -liberty $LIB
  opt_clean -purge
  tee -o reports/stat.txt stat -liberty $LIB
  write_verilog -noattr netlist/and_gate_net.v
" > /dev/null
echo "Done: reports/stat.txt  netlist/and_gate_net.v"
