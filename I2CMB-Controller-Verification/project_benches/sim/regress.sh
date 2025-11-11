make     cli GEN_TRANS_TYPE=i2cmb_generator
make     run_cli GEN_TRANS_TYPE=rw_wr_per_field
make     run_cli GEN_TRANS_TYPE=check_default_values
make     run_cli GEN_TRANS_TYPE=fsmr_check
make     run_cli GEN_TRANS_TYPE=regfield_aliasing_test
make     run_cli GEN_TRANS_TYPE=check_base_test
make merge_coverage

make view_coverage
