import uvm_pkg::*;
import decode_in_pkg::*;
import decode_out_pkg::*;
import decode_env_pkg::*;

class test_top extends uvm_test;
    `uvm_component_utils(test_top) // Register with the factory

    // Decode In components
    decode_in_agent agent_instance_in;
    decode_in_configuration config_instance_in;
    decode_in_sequence sequence_instance_in;
    virtual decode_in_if vif_in;

    // Decode Out components (without sequence, as it's passive)
    decode_out_agent agent_instance_out;
    decode_out_configuration config_instance_out;
    virtual decode_out_if vif_out;

    // Predictor instance
    decode_predictor predictor_instance;

    // Scoreboard instance
    decode_scoreboard my_scoreboard; // Updated scoreboard instance name

    // Constructor
    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("test_top", "Constructor called", UVM_LOW)
    endfunction

    // Build phase to create agent, configuration, sequence, and scoreboard instances
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("test_top", "Starting build_phase", UVM_LOW)

        // Create Decode In agent, configuration, and sequence
        agent_instance_in = decode_in_agent::type_id::create("decode_in_agent", this);
        `uvm_info("test_top", "Created decode_in_agent", UVM_LOW)
        config_instance_in = decode_in_configuration::type_id::create("decode_in_configuration", this);
        sequence_instance_in = decode_in_sequence::type_id::create("decode_in_sequence", this);
        predictor_instance = decode_predictor::type_id::create("decode_predictor", this);
        `uvm_info("test_top", "Created decode_predictor", UVM_LOW)

        // Retrieve the virtual interface for decode_in
        if (!uvm_config_db#(virtual decode_in_if)::get(null, "test_top", "decode_in_if", vif_in))
            `uvm_fatal("test_top", "Failed to retrieve decode_in_if virtual interface from uvm_config_db");

        // Set the configuration for decode_in
        uvm_config_db#(decode_in_configuration)::set(null, "test_top", "decode_in_configuration", config_instance_in);

        // Create Decode Out agent (passive, no sequence needed)
        agent_instance_out = decode_out_agent::type_id::create("decode_out_agent", this);
        config_instance_out = decode_out_configuration::type_id::create("decode_out_configuration", this);

        // Retrieve the virtual interface for decode_out
        if (!uvm_config_db#(virtual decode_out_if)::get(null, "test_top", "decode_out_if", vif_out))
            `uvm_fatal("test_top", "Failed to retrieve decode_out_if virtual interface from uvm_config_db");

        // Set the configuration for decode_out
        uvm_config_db#(decode_out_configuration)::set(null, "test_top", "decode_out_configuration", config_instance_out);

        // Create the scoreboard instance
        my_scoreboard = decode_scoreboard::type_id::create("my_scoreboard", this); // Scoreboard instantiation
        `uvm_info("test_top", "Created my_scoreboard", UVM_LOW)

    endfunction : build_phase

    // Connect phase to link the agent's analysis port to the predictor's analysis export and scoreboard
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("test_top", "Starting connect_phase", UVM_WARNING)

        // Connect agent's analysis port to the predictor's analysis export
        agent_instance_in.agent_ap.connect(predictor_instance.analysis_export);

        // Connect actual transactions from the decode_out_agent to the scoreboard
        agent_instance_out.agent_ap.connect(my_scoreboard.actual_analysis_export);

        // Connect expected transactions from the predictor to the scoreboard
        predictor_instance.decode_predictor_ap.connect(my_scoreboard.expected_analysis_export);

        `uvm_info("test_top", "Connected predictor and decode_out_agent to my_scoreboard", UVM_LOW)
    endfunction : connect_phase

    // Run phase to start sequences on decode_in and passively monitor decode_out
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        // Execute sequences on the decode_in agent
        repeat (50) begin // Execute 50 transactions or instructions for decode_in
            sequence_instance_in.start(agent_instance_in.my_sequencer);
        end

        // decode_out is only being passively monitored, no sequence needed
        `uvm_info("test_top", "Monitoring decode_out passively", UVM_LOW);

        phase.drop_objection(this);
    endtask : run_phase

endclass : test_top
