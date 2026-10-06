export PLATFORM = sky130hd
export DESIGN_NAME = and_gate

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_DIR)/rtl/*.sv))
export SDC_FILE = $(DESIGN_DIR)/constraint.sdc

export CORE_UTILIZATION = 40
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 15
export PLACE_DENSITY = 0.60
