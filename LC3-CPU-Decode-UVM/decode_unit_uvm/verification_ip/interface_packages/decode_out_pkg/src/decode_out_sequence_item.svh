class decode_out_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(decode_out_sequence_item)

  // Define the transaction fields that match your interface signals
  rand logic [15:0] IR;
  rand logic [5:0] E_Control;
  rand logic [15:0] npc_out;
  rand logic Mem_Control;
  rand logic [1:0] W_Control;
  rand logic enable_decode_out;

  // Default constructor
  function new(string name = "decode_out_sequence_item");
    super.new(name);
  endfunction

  // Function to compare two transactions
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    decode_out_sequence_item rhs_;
    assert($cast(rhs_, rhs));
    if (IR != rhs_.IR || E_Control != rhs_.E_Control ||
        npc_out != rhs_.npc_out || Mem_Control != rhs_.Mem_Control ||
        W_Control != rhs_.W_Control || enable_decode_out != rhs_.enable_decode_out)
      return 0;
    return 1;
  endfunction

  // Function to convert the transaction fields to a string (for debug purposes)
  function string convert2string();
    return $sformatf("IR=%0h, E_Control=%0h, npc_out=%0h, Mem_Control=%0b, W_Control=%0b, enable_decode_out=%0b",
                     IR, E_Control, npc_out, Mem_Control, W_Control, enable_decode_out);
  endfunction
endclass
