class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration  configuration;
  virtual i2c_if bus;

  T monitored_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    monitored_trans = new("monitored_trans");
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction
  
  virtual task run ();
      forever begin
        //$display(" i am inside the i2c_monitor");
      bus.monitor(monitored_trans.addr,
                  monitored_trans.op,
                  monitored_trans.data);
       /*$display("%s i2c_monitor::run() addr %h op %d data %d",
                 get_full_name(),
                 monitored_trans.addr, 
                 monitored_trans.op,
                 monitored_trans.data[0]
                 );*/   
      agent.nb_put(monitored_trans);
      end     
  endtask
endclass
