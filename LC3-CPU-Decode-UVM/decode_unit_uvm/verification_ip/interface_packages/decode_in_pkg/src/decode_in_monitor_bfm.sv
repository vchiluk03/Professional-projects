interface decode_in_monitor_bfm (decode_in_if bus);

	import decode_in_pkg::*;
	
	decode_in_pkg::decode_in_monitor monitor;
	
	event go;
	
	task monitor_task(output logic [15:0] instr_dout_m, 
					output logic enable_decode_m, 
					output logic [15:0] npc_in_m
					);
	
		instr_dout_m = bus.instr_dout;
		enable_decode_m = bus.enable_decode;
		npc_in_m = bus.npc_in;
	
	endtask: monitor_task
	
	initial 
	begin
		@go
		forever 
		begin
			logic [15:0] instr_dout;
			logic enable_decode;
			logic [15:0] npc_in;
			
			@(posedge bus.clock);
		
			monitor_task(instr_dout, enable_decode, npc_in);

			monitor.received_transaction(instr_dout, enable_decode, npc_in);
		end
	end

	
endinterface: decode_in_monitor_bfm