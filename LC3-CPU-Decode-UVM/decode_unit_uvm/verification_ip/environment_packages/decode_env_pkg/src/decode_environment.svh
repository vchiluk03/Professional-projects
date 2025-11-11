class decode_environment extends uvm_env;
	`uvm_component_utils(decode_environment)

    decode_in_agent agent_in;
    decode_out_agent agent_out;

    decode_scoreboard my_scoreboard;
    decode_predictor my_predictor;


    decode_in_configuration my_decode_in_configuration;
    decode_out_configuration my_decode_out_configuration;
    decode_env_configuration my_decode_env_configuration;


    function new(string name = "", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent_in = decode_in_agent::type_id::create("agent_in", this);
        agent_out = decode_out_agent::type_id::create("agent_out", this);
        my_predictor = decode_predictor::type_id::create("my_predictor",this);
        my_scoreboard = decode_scoreboard::type_id::create("my_scoreboard",this);

        agent_in.set_config(my_decode_in_configuration);
        agent_out.set_config(my_decode_out_configuration);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent_in.monitored_ap.connect(my_predictor.analysis_export);
        agent_out.monitored_ap.connect(my_scoreboard.actual_analysis_export);
        my_predictor.decode_predictor_ap.connect(my_scoreboard.expected_analysis_export);
    endfunction

    function void set_config(decode_env_configuration cfg);
        this.my_decode_env_configuration = cfg;
    endfunction




endclass