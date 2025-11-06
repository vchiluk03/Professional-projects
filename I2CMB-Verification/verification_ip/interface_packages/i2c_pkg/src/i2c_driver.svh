class i2c_driver extends ncsu_component#(.T(i2c_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual i2c_if bus;
  i2c_configuration configuration;
  i2c_transaction i2c_trans;
  //bit [7:0] r_data[];
  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    //$display("i am inside the blocking put of i2c driver");
    i2c_trans = trans;
   endtask

   virtual task run();
      forever begin
      //$display("i am inside the run task of i2c driver");
      bus.wait_for_i2c_transfer(i2c_trans.op,i2c_trans.data);
      //$display("i am after the wait for i2c transfer");
    if(i2c_trans.op == 1)
    begin
      //$display(" i am before the provide read data with value of r_dta is %d",i2c_trans.r_data);
      bus.provide_read_data(i2c_trans.r_data,i2c_trans.transfer_complete);
    end
      end
   endtask

endclass
