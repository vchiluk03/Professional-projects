class decode_out_agent extends uvm_agent;

    // Components in the agent
    decode_out_configuration my_config;
    decode_out_monitor my_monitor;
    //decode_out_coverage my_coverage;

    // Virtual interface for the monitor BFM
    virtual decode_out_monitor_bfm my_monitor_bfm;

    // Analysis port for broadcasting transactions
    uvm_analysis_port #(decode_out_sequence_item) agent_ap;

    // UVM factory registration
    `uvm_component_utils(decode_out_agent)

    // Constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);

        // Initialize the agent's analysis port
        agent_ap = new("agent_ap", this);

        // Retrieve the monitor BFM handle from the UVM configuration database
        uvm_config_db#(virtual decode_out_monitor_bfm)::get(null, "uvm_test_top", "decode_out_monitor_bfm", my_monitor_bfm);
    endfunction

    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_report_info("INFO", "Decode Out Agent Build phase", UVM_NONE);

        // Retrieve configuration object
        if (!uvm_config_db#(decode_out_configuration)::get(null, "*", "decode_out_configuration", my_config))
            `uvm_fatal("Decode Out Agent", "No decode_out_configuration found");

        // Instantiate the monitor
        my_monitor = decode_out_monitor::type_id::create("decode_out_monitor", this);
        //my_coverage = decode_out_coverage::type_id::create("decode_out_coverage", this);

        // Bind the monitor BFM
        my_monitor_bfm = this.my_monitor_bfm;
    endfunction : build_phase

    // Connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor to coverage
        //my_monitor.monitor_ap.connect(my_coverage.analysis_export);

        // Connect monitor to the agent's analysis port
        my_monitor.monitor_ap.connect(this.agent_ap);
    endfunction : connect_phase

endclass: decode_out_agent
