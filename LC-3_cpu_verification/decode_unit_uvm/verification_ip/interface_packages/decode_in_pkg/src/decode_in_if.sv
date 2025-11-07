interface decode_in_if(input wire clock, reset);

	//signal declaration
	logic [15:0] instr_dout;
	logic enable_decode;
	logic [15:0] npc_in;

	modport driver(
		input clock,
		input reset,
		output instr_dout,
		output enable_decode,
		output npc_in
	);

	modport monitor(
		input clock,
		input reset,
		input instr_dout,
		input enable_decode,
		input npc_in
	);

    
endinterface