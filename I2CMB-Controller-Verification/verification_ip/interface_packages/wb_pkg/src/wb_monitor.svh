class wb_monitor extends ncsu_component#(.T(wb_transaction));

  wb_configuration  configuration;
  virtual wb_if bus;

  T wb_monitored_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction
  
 virtual task run();
    bus.wait_for_reset();
      forever begin
        wb_monitored_trans = new("wb_monitored_trans");
        
        bus.master_monitor(wb_monitored_trans.addr,
                    wb_monitored_trans.data, wb_monitored_trans.we);
        
        //$display("%s wb_monitor::run() data %d", get_full_name(), wb_monitored_trans.data[0]);
        agent.nb_put(wb_monitored_trans);

        /*$display("%s wb_monitor::run() addr %h data %d",
                 get_full_name(),
                 wb_monitored_trans.addr, 
                 wb_monitored_trans.data
                 );
        agent.nb_put(wb_monitored_trans);
        if ( enable_transaction_viewing) begin
              wb_monitored_trans.end_time = $time;
              wb_monitored_trans.add_to_wave(transaction_viewing_stream);
            end*/


        end
  endtask  

endclass
