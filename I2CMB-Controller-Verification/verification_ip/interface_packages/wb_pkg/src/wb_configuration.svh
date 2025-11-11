class wb_configuration extends ncsu_configuration;
  
  function new(string name=""); 
    super.new(name);
    //wb_configuration = new("wb_configuration");
  endfunction

  virtual function string convert2string();
     return {super.convert2string};
  endfunction

endclass
