interface decode_in_driver_bfm(decode_in_if bus);

	task drive(input logic [15:0] instr_dout,
			   input enable_decode, 
			   input logic [15:0] npc_in
               );
	
		@(posedge bus.clock)
		
		bus.instr_dout <= instr_dout;
		bus.enable_decode <= enable_decode;
		bus.npc_in <= npc_in;
		
	endtask: drive
	
	
endinterface: decode_in_driver_bfm