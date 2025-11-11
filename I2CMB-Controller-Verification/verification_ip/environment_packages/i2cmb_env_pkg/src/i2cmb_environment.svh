class i2cmb_environment extends ncsu_component#(.T(wb_transaction));

  i2cmb_env_configuration configuration;
  wb_agent         wb_age;
  i2c_agent        i2c_age;
  i2cmb_predictor         pred;
  i2cmb_scoreboard        scbd;
  i2cmb_coverage          coverage;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void build();
    wb_age = new("wb_age",this);
    wb_age.set_configuration(configuration.wb_agent_config);
    wb_age.build();
    i2c_age = new("i2c_age",this);
    i2c_age.set_configuration(configuration.i2c_agent_config);
    i2c_age.build();
    pred  = new("pred", this);
    pred.set_configuration(configuration);
    pred.build();
    scbd  = new("scbd", this);
    scbd.build();
    coverage = new("coverage", this);
    coverage.set_configuration(configuration);
    wb_age.connect_subscriber(coverage);
    wb_age.connect_subscriber(pred);
    pred.set_scoreboard(scbd);
    i2c_age.connect_subscriber(scbd);
  endfunction
  
  function ncsu_component#(T) get_wb_agent();
    return wb_age;
  endfunction

  function ncsu_component#(i2c_transaction) get_i2c_agent();
    return i2c_age;
  endfunction

  virtual task run();
     wb_age.run();
     i2c_age.run();
  endtask

endclass
