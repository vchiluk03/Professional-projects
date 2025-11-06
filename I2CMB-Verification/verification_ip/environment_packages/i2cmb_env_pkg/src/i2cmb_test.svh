class i2cmb_test extends ncsu_component#(.T(wb_transaction));
  i2cmb_env_configuration  cfg;
  i2cmb_environment        env;
  i2cmb_generator          gen;
  string gen_trans_name;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    cfg = new("cfg");
    env = new("env",this);
    env.set_configuration(cfg);
    env.build();
    gen = new("gen",this);
    gen.set_wb_agent(env.get_wb_agent());
    gen.set_i2c_agent(env.get_i2c_agent());
    if ( !$value$plusargs("GEN_TRANS_TYPE=%s", gen_trans_name)) begin
      $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
      $fatal;
    end
    $display("%m found +GEN_TRANS_TYPE=%s", gen_trans_name);    
  endfunction

  virtual task run();
     env.run();
    if(gen_trans_name == "rw_wr_per_field" )
      gen.rw_wr_per_field();
    else if(gen_trans_name == "check_default_values")
      gen.check_default_values();
    else if(gen_trans_name == "fsmr_check")
      gen.fsmr_check();
    else if(gen_trans_name == "regfield_aliasing_test")
        gen.regfield_aliasing_test();
    else
    gen.run();
  endtask
endclass
