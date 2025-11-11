class decode_predictor extends uvm_subscriber #(decode_in_sequence_item);
    `uvm_component_utils(decode_predictor)

    uvm_analysis_port #(decode_out_sequence_item) decode_predictor_ap; // Analysis port to send out
    decode_out_sequence_item trans_out; // Updated type

    // Updated constructor with default parent
    function new (string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Initialized decode_predictor_ap", UVM_LOW)
        decode_predictor_ap = new("decode_predictor_ap", this); // To broadcast decoded transactions
        //pred_analysis_imp = new("pred_analysis_imp", this);
    endfunction

    // This function will receive transactions from the decode_in_agent
    virtual function void write(decode_in_sequence_item t);
        bit decode_model_return_type;
        `uvm_info(get_type_name(), $sformatf("Received transaction: %0p", t), UVM_LOW)
        trans_out = new(); // Create a new decode_out transaction
        
        // Call the model to process inputs and generate decoded outputs
        decode_model_return_type = decode_model(
            t.instr_dout,         // Instruction Decode Output from decode_in
            t.npc_in,             // NPC (Next Program Counter) from decode_in
            trans_out.IR,         // Decoded output: Instruction Register (IR)
            trans_out.npc_out,    // Decoded output: NPC (Next Program Counter)
            trans_out.E_Control,  // Decoded output: Execution Control signals
            trans_out.W_Control,  // Decoded output: Write Control signals
            trans_out.Mem_Control // Decoded output: Memory Control signals
        );

        // Assign other fields if necessary, such as the enable_decode_out signal
        trans_out.enable_decode_out = t.enable_decode;
        
        // Write the decoded transaction to the analysis port
        decode_predictor_ap.write(trans_out);
    endfunction

endclass: decode_predictor
