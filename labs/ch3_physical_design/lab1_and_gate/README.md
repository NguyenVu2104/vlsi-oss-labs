Lab 1 — AND Gate: Synthesis and Floorplan/PDN Failure Analysis

Overview

The purpose is not to push a trivial AND gate through a complete RTL-to-GDS flow, but to establish a reproducible ORFS workflow and learn how to inspect intermediate stages, reports, configuration variables, and failures.

The experiment uses OpenROAD-flow-scripts (ORFS) at commit d90873f47 (2026-05-30) with the sky130hd platform.

The lab intentionally starts from a very small design so that the relationship between logical design size, floorplan geometry, standard-cell rows, and PDN requirements can be observed directly.

Directory structure

lab1_and_gate/
├── rtl/
│   └── and_gate.sv
├── config.mk
├── constraint.sdc
├── reports/
├── README.md
└── work/                  # generated ORFS data; do not commit

Design

The RTL is a combinational 2-input AND gate:

module and_gate (
    input  logic a,
    input  logic b,
    output logic y
);
    assign y = a & b;
endmodule

No clock or sequential element is present.

ORFS configuration

Initial configuration:

export PLATFORM = sky130hd
export DESIGN_NAME = and_gate

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_DIR)/rtl/*.sv))
export SDC_FILE = $(DESIGN_DIR)/constraint.sdc

export CORE_UTILIZATION = 40
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2
export PLACE_DENSITY = 0.60

Constraints:

set_input_delay 0.0 [all_inputs]
set_output_delay 0.0 [all_outputs]

Because the design is purely combinational, no clock constraint is defined.

The floorplan target contains multiple internal stages:

2_1_floorplan
2_2_floorplan_macro
2_3_floorplan_tapcell
2_4_floorplan_pdn

Result 1 — Synthesis succeeded

The synthesis stage completed successfully.

Key result from synth_stat.txt:

3 wires
3 wire bits
3 public wires
3 public wire bits
3 ports
3 port bits
1 cell
6.256 area
sky130_fd_sc_hd__and2_1
sequential elements: 0

Interpretation:

The RTL AND operation was technology-mapped to one SKY130HD standard cell:
sky130_fd_sc_hd__and2_1.

The design contains no sequential logic.

The mapped cell area reported by Yosys is 6.256.

Synthesis checking reported zero problems.

This establishes the first important link:

RTL AND gate
    ↓
technology mapping
    ↓
one physical standard cell

Result 2 — Initial floorplan reached PDN and failed

With CORE_MARGIN = 2, stages 2_1, 2_2, and 2_3 completed.

Important floorplan data:

Die BBox:   (0.000, 0.000) to (7.955, 7.955) um
Core BBox:  (2.300, 2.720) to (5.520, 5.440) um

Core width:  3.220 um
Core height: 2.720 um

Core area:            8.758 um^2
Total instances area: 6.256 um^2
Effective utilization: 0.714
Number of instances: 1

The floorplan also reported that no macros were present and zero tapcells were inserted.

The failure occurred at:

2_4_floorplan_pdn

Error:

[ERROR PDN-0185] Insufficient width (3.22 um) to add straps on layer met4
in grid "grid" with total strap width 15.2 um and offset 13.6 um.

This is not a synthesis or RTL error. The design has already been floorplanned successfully; the failure is caused by the physical geometry being too small for the default SKY130HD PDN configuration.

The relevant default PDN configuration is:

add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {5.44} -offset {0} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.600} -pitch {27.140} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.600} -pitch {27.200} -offset {13.600}

The exact error should be interpreted as a PDN-geometry feasibility failure rather than as a simple statement that the core must literally contain 15.2 um of physical strap width.

Important lesson:

very small logical design
    ↓
very small floorplan
    ↓
limited physical geometry
    ↓
default PDN geometry becomes infeasible

Debugging step — Changing CORE_MARGIN

To test whether floorplan sizing was involved, CORE_MARGIN was changed from:

export CORE_MARGIN = 2

to:

export CORE_MARGIN = 15

The first re-run unexpectedly produced the same 3.22 um PDN error. The reason was not that the variable was ignored. ORFS had reused previously generated intermediate floorplan outputs.

The stale floorplan outputs were removed:

rm -f work/results/sky130hd/and_gate/base/2_*.odb
rm -f work/results/sky130hd/and_gate/base/2_*.sdc

The floorplan was then re-run from 2_1_floorplan.

This time the new log proved that CORE_MARGIN = 15 was actually applied:

[INFO IFP-0107] Defining die area using utilization: 40.00% and aspect ratio: 1.
[WARNING IFP-0028] Core area lower left (15.000, 15.000) snapped to (15.180, 16.320).

However, the run failed earlier:

[WARNING IFP-0061] No rows created for site unithd.
[ERROR IFP-0065] No rows created in the core area.

The 15 um margin consumed too much of the die generated from the 40% utilization setting, leaving no valid standard-cell row region.

Therefore:

CORE_MARGIN = 2
    → valid rows
    → PDN failure

CORE_MARGIN = 15
    → no standard-cell rows
    → floorplan failure before PDN

This experiment demonstrates that floorplan parameters are coupled. They cannot be tuned independently without considering the geometry produced by the overall floorplan calculation.

Mistakes and debugging lessons

1. A configuration change may not immediately affect an ORFS run

Changing config.mk is not sufficient when a target can reuse existing intermediate results.

The observed stale-result problem was:

change config
    ↓
run floorplan
    ↓
old 2_x outputs are still present
    ↓
later stage can reuse old geometry

The correct debugging habit is to verify whether the relevant stage actually reran and, when necessary, remove only the affected intermediate outputs.

2. Do not tune PDN blindly just to make a tiny design pass

The first instinct could be to modify strap width/pitch or otherwise customize the platform PDN configuration.

That is not the preferred approach for this learning lab because the failure is informative: the AND gate is simply too small to be a natural test vehicle for the default full-chip PDN configuration.

Changing PDN rules just to force this design through the flow would hide the physical relationship we are trying to learn.

3. CORE_UTILIZATION is a target, not necessarily the final effective utilization

The requested utilization was:

CORE_UTILIZATION = 40%

but the resulting effective utilization was approximately:

71.4%

The difference is a consequence of the tiny design and the quantized physical geometry/standard-cell row construction.

Therefore, the configured utilization value should not be confused with the final reported effective utilization.

4. A trivial design is useful for early stages but poor for all stages

The AND gate is a good educational vehicle for:

RTL
→ synthesis
→ technology mapping
→ basic floorplan inspection

It is not a good vehicle for studying a realistic default PDN, placement, CTS, routing, timing closure, or signoff flow.

This led to the agreed project direction:

Keep the AND gate as a small early-stage and failure-analysis lab, rather than forcing it through complete RTL-to-GDS.
