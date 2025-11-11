class decode_in_sequence extends uvm_sequence#(decode_in_sequence_item);
	
	decode_in_sequence_item sequence_request;
	
	`uvm_object_utils(decode_in_sequence)
	
	function new(string name = ""); //constructer
		super.new(name);
	endfunction
	
	virtual task body(); //randomize transactions here
	
		`uvm_info("SEQUENCE","Requesting to send transaction to driver",UVM_NONE);
		sequence_request = decode_in_sequence_item::type_id::create("decode_in_sequence_item");
		
		start_item(sequence_request);
		
		if(!sequence_request.randomize()) begin
			`uvm_fatal(get_type_name(), " Randomization Failed!");
		end

		finish_item(sequence_request);
		
		uvm_report_info("SEQUENCE","Transaction received from driver", UVM_NONE);
	
	endtask

endclass