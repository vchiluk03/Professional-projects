class decode_out_monitor extends uvm_monitor;

    // -------------------------
    // UVM Factory Registration
    // -------------------------
    
    `uvm_component_utils(decode_out_monitor);
    // Registers the decode_out_monitor class with the UVM factory.

    // -------------------------
    // Virtual Interface Handle
    // -------------------------
    
    virtual decode_out_monitor_bfm my_monitor_bfm;
    // Virtual interface handle for the monitor's Bus Functional Model (BFM).
    
    // -------------------------
    // Analysis Port
    // -------------------------
    
    uvm_analysis_port #(decode_out_sequence_item) monitor_ap;
    // Analysis port to broadcast decode_out_sequence_item transactions.

    // -------------------------
    // Sequence Item Instance
    // -------------------------
    
    decode_out_sequence_item sequence_collected;
    // Instance of decode_out_sequence_item to hold the collected transaction data.

    // -------------------------
    // Constructor
    // -------------------------
    
    function new(string name, uvm_component parent); 
        super.new(name, parent);
        sequence_collected = new();
        monitor_ap = new("monitor_ap", this);
        // Initialize analysis port.
    endfunction

    // -------------------------
    // Build Phase
    // -------------------------
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Retrieve the virtual interface handle for the monitor BFM from the UVM config DB.
        if (!uvm_config_db#(virtual decode_out_monitor_bfm)::get(null, "*", "decode_out_monitor_bfm", my_monitor_bfm))
            `uvm_fatal("Decode Out Monitor", "Virtual interface not set for decode_out_monitor_bfm");
        
        set_proxy_bfm();
    endfunction

    // -------------------------
    // Set Proxy BFM
    // -------------------------
    
    virtual function void set_proxy_bfm();
        my_monitor_bfm.monitor = this;
    endfunction

    // -------------------------
    // Run Phase
    // -------------------------
    
    virtual task run_phase(uvm_phase phase);
    begin
        `uvm_info("DECODE_OUT_MONITOR", "Monitoring started...", UVM_LOW);
        ->my_monitor_bfm.go;
        // Trigger the 'go' event in the monitor BFM to start monitoring DUT signals.
    end
    endtask: run_phase

    // -------------------------
    // Collect Transaction
    // -------------------------
    
    virtual function void collect_transaction(
        logic [15:0] IR,
        logic [5:0] E_Control,
        logic [15:0] npc_out,
        logic Mem_Control,
        logic [1:0] W_Control,
        logic enable_decode_out
    );
        sequence_collected = decode_out_sequence_item::type_id::create("sequence_collected");

        // Sample the signals passed from the BFM
        sequence_collected.IR = IR;
        sequence_collected.E_Control = E_Control;
        sequence_collected.npc_out = npc_out;
        sequence_collected.Mem_Control = Mem_Control;
        sequence_collected.W_Control = W_Control;
        sequence_collected.enable_decode_out = enable_decode_out;

        // Log the collected transaction for debugging
        `uvm_info("DECODE_OUT_MONITOR", {"Collected transaction: ", sequence_collected.convert2string()}, UVM_LOW);
        `uvm_info("DECODE_OUT_MONITOR", $sformatf("Collected transaction - IR=%h, E_Control=%h, npc_out=%h, Mem_Control=%b, W_Control=%b, enable_decode_out=%b",
            IR, E_Control, npc_out, Mem_Control, W_Control, enable_decode_out), UVM_LOW);

        // Send the collected transaction through the analysis port
        monitor_ap.write(sequence_collected);
    endfunction

endclass: decode_out_monitor
