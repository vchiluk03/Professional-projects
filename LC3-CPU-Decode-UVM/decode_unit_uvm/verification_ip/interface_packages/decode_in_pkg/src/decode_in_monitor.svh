class decode_in_monitor extends uvm_monitor;

	`uvm_component_utils(decode_in_monitor);
	
	virtual decode_in_monitor_bfm my_monitor_bfm;

	uvm_analysis_port #(decode_in_sequence_item) monitor_ap;

	decode_in_sequence_item sequence_collected;
	

	time time_stamp;
	int transaction_stream;
	
	function new(string name, uvm_component parent); 
		super.new(name,parent);
		sequence_collected = new();
		monitor_ap = new("monitor_ap", this);
    endfunction
	
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		//uvm_report_info("MONITOR build", UVM_NONE);
		
		if(!uvm_config_db#(virtual decode_in_monitor_bfm)::get(null, "*", "decode_in_monitor_bfm", my_monitor_bfm))
			`uvm_fatal("Decode Monitor", "decode_in_monitor_bfm not found");
		
		time_stamp = $time;
		set_proxy_bfm();
		
	endfunction: build_phase
	
	
	
	virtual function void start_of_simulation_phase(uvm_phase phase);
		transaction_stream = $create_transaction_stream({"..", get_full_name(), ".","txn_stream"});
	endfunction: start_of_simulation_phase
	
	
	virtual task run_phase(uvm_phase phase);
	begin	
		->my_monitor_bfm.go;
	end
	endtask: run_phase
	
	
	virtual function void set_proxy_bfm();
		my_monitor_bfm.monitor = this;
	endfunction: set_proxy_bfm
	
	virtual function void analyze(decode_in_sequence_item request);
		request.add_to_wave(transaction_stream);
		uvm_report_info("MONITOR_PROXY", {"Observed signals and broadcasting transaction: ",request.convert2string()},UVM_NONE);

	endfunction: analyze
	
	virtual function void received_transaction(input logic [15:0] instr_dout,
			   input logic enable_decode,
			   input logic [15:0] npc_in
			   );
		
		sequence_collected = new();
		
		sequence_collected.start_time = time_stamp;
		sequence_collected.end_time = $time;
		time_stamp = sequence_collected.end_time;
		
		sequence_collected.instr_dout = instr_dout;
		sequence_collected.enable_decode = enable_decode;
		sequence_collected.npc_in = npc_in;
		
		monitor_ap.write(sequence_collected);
		
		analyze(sequence_collected);
	endfunction: received_transaction
	
	
endclass: decode_in_monitor