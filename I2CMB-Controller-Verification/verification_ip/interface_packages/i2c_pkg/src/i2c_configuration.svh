class i2c_configuration extends ncsu_configuration;
  
  function new(string name=""); 
    super.new(name);
    //i2c_configuration = new;
  endfunction

  virtual function string convert2string();
     return {super.convert2string};
  endfunction

endclass
