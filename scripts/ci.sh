#!/usr/bin/env bash
# Lint + simulate selected labs (testbench top module must be named "tb").
# Usage: scripts/ci.sh <lab_dir>...   explicit labs (use while a lab is in progress)
#        scripts/ci.sh                labs listed in scripts/ci_labs.txt (used by CI)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ $# -gt 0 ]; then
  labs=("$@")
else
  mapfile -t labs < <(grep -vE '^[[:space:]]*(#|$)' scripts/ci_labs.txt)
fi
[ ${#labs[@]} -gt 0 ] || { echo "No labs selected"; exit 1; }

for lab in "${labs[@]}"; do
  lab="${lab%/}"
  [ -f "$lab/tb/tb.sv" ] || { echo "ERROR: $lab/tb/tb.sv not found"; exit 1; }
  echo "=== $lab: lint ==="
  verilator --lint-only -Wall --timing --timescale 1ns/1ps --top-module tb "$lab"/rtl/*.sv "$lab"/tb/tb.sv
  echo "=== $lab: simulation ==="
  verilator --binary -j 0 --timing --timescale 1ns/1ps --assert --top-module tb \
            --Mdir "$lab/build" "$lab"/rtl/*.sv "$lab"/tb/tb.sv > "$lab/build.log" 2>&1 || { cat "$lab/build.log"; exit 1; }
  ( cd "$lab" && ./build/Vtb )
done
echo "=== ALL CHECKS PASSED ==="
EOF