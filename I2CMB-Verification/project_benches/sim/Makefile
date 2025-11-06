export ECE745_PROJECT_HOME ?= $(PWD)/../..

GEN_TRANS_TYPE ?= i2cmb_generator

CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TRANS_TYPE); \
                    quit -f;" 


include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

clean: 
	rm -rf work *.wlf transcript

comp_I2C_MB:
	vcom +cover=bsft -coverenhanced ../rtl/iicmb_int_pkg.vhd
	vcom +cover=bsft -coverenhanced ../rtl/iicmb_pkg.vhd
	vcom +cover=bsft -coverenhanced ../rtl/mbyte.vhd
	vcom +cover=bsft -coverenhanced ../rtl/mbit.vhd
	vcom +cover=bsft -coverenhanced ../rtl/bus_state.vhd
	vcom +cover=f -coverenhanced ../rtl/filter.vhd
	vcom +cover=f -coverenhanced ../rtl/conditioner.vhd
	vcom +cover=bsft -coverenhanced ../rtl/conditioner_mux.vhd
	vcom +cover=bsft -coverenhanced ../rtl/iicmb_m.vhd
	vcom +cover=bsft -coverenhanced ../rtl/regblock.vhd
	vcom +cover=bsft -coverenhanced ../rtl/wishbone.vhd
	vcom +cover=bsft -coverenhanced ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_wb_pkg comp_common_pkg comp_i2c_pkg comp_i2cmb_env_pkg
	vlog +cover ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

run_cli:
	vsim -c -coverage  $(CLI_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

merge_coverage:
	xml2ucdb -format Excel ./vchiluk3_test_plan.xml ./test_plan_layered_testbench.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 

regress:
	./regress.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

debug: clean compile simulate
