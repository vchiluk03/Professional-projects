class decode_in_driver extends uvm_driver #(decode_in_sequence_item);

	virtual decode_in_driver_bfm my_driver_if;	//virtual interface
	
	decode_in_sequence_item sequence_request; //sequence item as a request
	
	`uvm_component_utils(decode_in_driver);
	
	function new (string name="", uvm_component parent = null); 
		super.new(name, parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		//uvm_report_info("INFO","Driver build", UVM_NONE);
		
		if(!uvm_config_db#(virtual decode_in_driver_bfm)::get(null, "*", "decode_in_driver_bfm",my_driver_if))
			`uvm_fatal("Decode Driver","No decode_in_driver_bfm");
			
	endfunction: build_phase
	
	virtual task run_phase(uvm_phase phase);
	
	
	forever
	begin
		//`uvm_info("DRIVER","Sequencer request transaction",UVM_NONE)
		seq_item_port.get_next_item(sequence_request);
		
		my_driver_if.drive(sequence_request.instr_dout, sequence_request.enable_decode, sequence_request.npc_in);
		
		seq_item_port.item_done();
	end
	endtask: run_phase
	
endclass: decode_in_driver