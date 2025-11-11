class decode_in_agent extends uvm_agent;

	decode_in_configuration my_config;
	decode_in_driver my_driver;
	decode_in_monitor my_monitor;
	decode_in_coverage	my_coverage;
	decode_in_sequencer my_sequencer;
	
	virtual decode_in_monitor_bfm my_monitor_bfm;
	virtual decode_in_driver_bfm my_driver_bfm;
	
	uvm_analysis_port #(decode_in_sequence_item) agent_ap;
	
	`uvm_component_utils(decode_in_agent);
	
	function new (string name, uvm_component parent);
		super.new(name, parent);
		agent_ap = new("agent_ap", this);

		uvm_config_db #(virtual decode_in_monitor_bfm)::get(null,"uvm_test_top","decode_in_monitor_bfm",my_monitor_bfm);
		uvm_config_db #(virtual decode_in_driver_bfm)::get(null,"uvm_test_top","decode_in_driver_bfm",my_driver_bfm);
		
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		uvm_report_info("INFO","Decode Agent Build phase", UVM_NONE);
		
		if(!uvm_config_db#(decode_in_configuration)::get(null, "*", "decode_in_configuration", my_config))
			`uvm_fatal("Decode agent","no decode_in_configuration found");
			
		if(my_config.active_flag == 1) begin
			my_driver = decode_in_driver::type_id::create("decode_in_driver", this);
			my_sequencer = decode_in_sequencer::type_id::create("decode_in_sequencer", this);
			my_driver.my_driver_if = this.my_driver_bfm;
		end
		
		my_monitor = decode_in_monitor::type_id::create("decode_in_monitor", this);
		my_coverage = decode_in_coverage::type_id::create("decode_in_coverage", this);
		my_monitor.my_monitor_bfm = this.my_monitor_bfm;
		
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(my_config.active_flag == 1'b1) begin
			my_driver.seq_item_port.connect(my_sequencer.seq_item_export); 
		end
		my_monitor.monitor_ap.connect(my_coverage.analysis_export);  //Connecting Monitor and Coverage
		my_monitor.monitor_ap.connect(this.agent_ap); // Covering Monitor with Agent analysis port
	endfunction : connect_phase
	
	
	
endclass: decode_in_agent