class wb_driver extends ncsu_component#(.T(wb_transaction));

  virtual wb_if  bus;
  wb_configuration configuration;
  wb_transaction wb_trans;
  bit [7:0] temp_data;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    //$display({get_full_name()," ",trans.convert2string()});
  /*  bus.wait_for_reset();
    bus.master_write(trans.addr,trans.data);
    if(trans.addr == 2'b10)
    begin
      bus.wait_for_interrupt();
      bus.master_read(2'b10,trans.data);
    end*/
    //bus.wait_for_reset();
    //bus.wait_for_interrupt();
    //bus.master_write(trans.addr,trans.data);
    //bus.master_read(trans.addr,trans.data);
  endtask

    virtual task check_don_bit();
    bus.wait_for_interrupt();
    bus.master_read(2'b10,temp_data);
    endtask

   virtual task mstr_write(T trans);
    bus.master_write(trans.addr,trans.data);
   endtask

   virtual task mstr_read(T trans);
    bus.master_read(trans.addr,trans.data);
   endtask


endclass
