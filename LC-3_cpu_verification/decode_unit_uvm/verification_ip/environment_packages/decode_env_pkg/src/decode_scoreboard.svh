class decode_scoreboard extends uvm_component;
    `uvm_component_utils(decode_scoreboard)

    `uvm_analysis_imp_decl(_expected_ae)   // Declare analysis implementation for expected transactions
    `uvm_analysis_imp_decl(_actual_ae)     // Declare analysis implementation for actual transactions

    uvm_analysis_imp_expected_ae #(decode_out_sequence_item, decode_scoreboard) expected_analysis_export;
    uvm_analysis_imp_actual_ae #(decode_out_sequence_item, decode_scoreboard) actual_analysis_export;

    decode_out_sequence_item expected_q[$];  // Queue to store expected transactions
    decode_out_sequence_item decode_out_transaction_h;

    event entry_rxd;     // Event to signal transaction comparison
    int report_var[3];   // Variable array to store report counts
    bit end_of_test_activity_check = 1;
    bit wait_for_empty_scoreboard = 0;
    int nothing_to_compare = 0;
    int trans_match;
    int trans_mismatch;
    int expected_trans;

    function new(string name=" ", uvm_component parent);
        super.new(name,parent);
        trans_match = 0;
        trans_mismatch = 0;
        expected_trans = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        expected_analysis_export = new("expected_analysis_export", this);  // Initialize expected analysis export
        actual_analysis_export = new("actual_analysis_export", this);      // Initialize actual analysis export
    endfunction

    // Function to write expected transactions to the scoreboard
    virtual function void write_expected_ae(decode_out_sequence_item seq_item1);
        expected_q.push_back(seq_item1);  // Push the expected transaction into the queue
        expected_trans++;                 // Increment expected transaction count
        ->entry_rxd;                      // Trigger event
    endfunction

virtual function void write_actual_ae(decode_out_sequence_item actual);
  // ✅ Declare all variables at the very top
  uvm_comparer cmp;

  `uvm_info(get_type_name(), "write_actual_ae: Received actual transaction.", UVM_MEDIUM);

  if (actual == null) begin
    trans_mismatch++;
    `uvm_error("SCOREBOARD", "Received NULL actual transaction");
    return;
  end

  -> entry_rxd;

  if (expected_q.size() == 0) begin
    trans_mismatch++;
    `uvm_error("SCOREBOARD",
      $sformatf("UNEXPECTED TRANSACTION\nACTUAL = %s\nNo corresponding expected transaction found.",
                actual.convert2string()));
    return;
  end

  decode_out_transaction_h = expected_q.pop_front();
  if (decode_out_transaction_h == null) begin
    trans_mismatch++;
    `uvm_error("SCOREBOARD", "Popped NULL expected transaction from queue");
    return;
  end

  cmp = new(); // ✅ construct after declared at top

  if (actual.do_compare(decode_out_transaction_h, cmp)) begin
    trans_match++;
    `uvm_info("SCOREBOARD",
      $sformatf("TRANSACTION MATCH\nACTUAL   = %s\nEXPECTED = %s",
                actual.convert2string(), decode_out_transaction_h.convert2string()),
      UVM_MEDIUM);
  end else begin
    trans_mismatch++;
    `uvm_error("SCOREBOARD",
      $sformatf("TRANSACTION MISMATCH\nACTUAL   = %s\nEXPECTED = %s",
                actual.convert2string(), decode_out_transaction_h.convert2string()));
  end

  report_var[0] = expected_trans;
  report_var[1] = trans_match;
  report_var[2] = trans_mismatch;
endfunction



    // Check phase to ensure all expected transactions were compared
 virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if(expected_q.size() != 0) begin
            `uvm_error($sformatf("SCOREBOARD_ERROR,%s",this.get_full_name()), "SCOREBOARD NOT EMPTY");
        end
        if(end_of_test_activity_check == 1 && expected_trans == 0) begin
            `uvm_error($sformatf("SCOREBOARD_ERROR,%s",this.get_full_name()), "SCOREBOARD NOT USED");
        end
    endfunction: check_phase

    // Function to delay the end of the phase until the scoreboard is empty
    virtual function void phase_ready_to_end(uvm_phase phase);
        if(phase.get_name() == "run") begin
            if(wait_for_empty_scoreboard) begin
                phase.raise_objection(this, {get_full_name(), " Delaying SCOREBOARD"});
                fork begin
                    wait_for_drain();
                    phase.drop_objection(this, {get_full_name(), " Done with SCOREBOARD"});
                end
                join_none
            end
        end
    endfunction

    // Task to wait until the scoreboard queue is drained
    task wait_for_drain();
        while(expected_q.size() != 0) begin
            @entry_rxd;
        end
    endtask

    // Function to format the report message
    virtual function string report_message(int variables[]);
        return $sformatf("\n PREDICTED TRANSACTIONS = %0d \n MATCHES = %0d \n MISMATCHES = %0d", variables[0],variables[1],variables[2]);
    endfunction

    // Report phase to log the scoreboard summary
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info($sformatf("SCOREBOARD_SUMMARY,%s \n",this.get_full_name()), report_message(report_var), UVM_LOW);
    endfunction
endclass
