
package i2cmb_env_pkg;
	import ncsu_pkg::*;
	import i2c_pkg::*;
	import wb_pkg::*;
	import enumtype_i2c::*;
	`include "../../ncsu_pkg/ncsu_macros.svh"

	`include "src/i2cmb_generator.svh"
	`include "src/i2cmb_env_configuration.svh"
	`include "src/i2cmb_predictor.svh"
	`include "src/i2cmb_scoreboard.svh"
	`include "src/i2cmb_coverage.svh"
	`include "src/i2cmb_environment.svh"
	`include "src/check_base_test.svh"
	`include "src/i2cmb_test.svh"

endpackage