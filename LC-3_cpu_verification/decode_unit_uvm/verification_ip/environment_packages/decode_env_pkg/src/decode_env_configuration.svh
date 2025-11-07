class decode_env_configuration extends uvm_object;
	`uvm_object_utils(decode_env_configuration)

	decode_in_configuration decode_in_agent_config;
	decode_out_configuration decode_out_agent_config;

    function new(string name="");
        super.new(name);

        decode_in_agent_config = decode_in_configuration::type_id::create("decode_in_agent_config");

        decode_out_agent_config = decode_out_configuration::type_id::create("decode_out_agent_config");
    endfunction

    virtual function void initialize(uvmf_active_passive_t interface_activities[], string env_path[], string interface_names[]);
        
        decode_in_agent_config.initialize(interface_activities[0],env_path[0],interface_names[0]);
        decode_out_agent_config.initialize(interface_activities[1],env_path[1],interface_names[1]);
        decode_in_agent_config.initiator_responder = INITIATOR;
        decode_out_agent_config.initiator_responder = INITIATOR;
    
    endfunction

endclass: decode_env_configuration