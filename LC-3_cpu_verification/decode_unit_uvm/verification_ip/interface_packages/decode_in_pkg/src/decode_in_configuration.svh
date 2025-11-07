class decode_in_configuration extends uvm_component;
	
	virtual  decode_in_driver_bfm	my_driver_bfm;
	virtual decode_in_monitor_bfm	my_monitor_bfm;
	
	`uvm_component_utils(decode_in_configuration);
	
	bit enable_viewing =1;
	bit active_flag = 1;
	
	function new(string name = "", uvm_component parent);
		super.new(name, parent);
		if(!uvm_config_db#(virtual decode_in_driver_bfm)::get(null, "*", "decode_in_driver_bfm", my_driver_bfm))
			`uvm_fatal("Decode Configuration error", "driver_bfm not found");
	
		if(!uvm_config_db#(virtual decode_in_monitor_bfm)::get(null, "*", "decode_in_monitor_bfm", my_monitor_bfm))
		   `uvm_fatal("Decode Configuration error", "monitor_bfm not found");
		
		uvm_config_db#(decode_in_configuration)::set(null,"*","decode_in_configuration",this);
	
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
	
endclass: decode_in_configuration