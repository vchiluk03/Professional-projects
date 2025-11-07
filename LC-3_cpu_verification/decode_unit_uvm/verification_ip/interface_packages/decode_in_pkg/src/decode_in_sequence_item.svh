class decode_in_sequence_item extends uvm_sequence_item;
	
	//data and control fields
	rand bit [15:0] npc_in;
	rand bit [15:0] instr_dout;
	rand bit enable_decode;
	
	time start_time;
	time end_time;
	int view_transaction;
	
	`uvm_object_utils(decode_in_sequence_item)
	
	function new(string name = "");
		super.new(name);
	endfunction
	
    constraint ENABLE_ALWAYS_HIGH {
		enable_decode != 0;
	}
    
    constraint OPCODES_NOT_USED {
		!(instr_dout[15:12] inside {4, 8, 13, 15});
	}

	constraint NPC_MINIMUM{
		 npc_in >= 16'h3000;
	}

	virtual function string convert2string();
		return $sformatf("instr_dout = %h, npc_in = %h", instr_dout, npc_in);
	endfunction: convert2string
	
	virtual function void add_to_wave(int transaction_stream);
    view_transaction = $begin_transaction(transaction_stream,"decode_in_sequence_item",start_time);
    $add_attribute(view_transaction, enable_decode, "enable_decode" );
    $add_attribute(view_transaction, instr_dout, "instr_dout" );
	$add_attribute(view_transaction, npc_in, "npc_in" );
    $end_transaction(view_transaction,end_time);
    $free_transaction(view_transaction);
  endfunction

endclass: decode_in_sequence_item