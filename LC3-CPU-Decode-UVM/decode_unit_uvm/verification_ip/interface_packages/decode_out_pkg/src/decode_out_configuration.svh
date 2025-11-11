class decode_out_configuration extends uvm_component;

    // Virtual interface handle for monitor BFM
    virtual decode_out_monitor_bfm my_monitor_bfm;

    // Flags to control viewing and activity
    bit enable_viewing = 1;
    bit active_flag = 1;

    // UVM factory registration
    `uvm_component_utils(decode_out_configuration)

    // Constructor
    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);

        // Retrieve the monitor BFM from the UVM configuration database
        if(!uvm_config_db#(virtual decode_out_monitor_bfm)::get(null, "*", "decode_out_monitor_bfm", my_monitor_bfm))
            `uvm_fatal("Decode Configuration error", "monitor_bfm not found");

        // Set this configuration object in the UVM configuration database
        uvm_config_db#(decode_out_configuration)::set(null, "*", "decode_out_configuration", this);
    endfunction

    // Build phase (can be used for additional setup if needed)
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

endclass: decode_out_configuration
