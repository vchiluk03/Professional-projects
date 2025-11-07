class decode_in_coverage extends uvm_subscriber#(decode_in_sequence_item);

	decode_in_sequence_item sequence_request;
	
	`uvm_component_utils(decode_in_coverage);
	
	int counter;
	covergroup decode_in_cg;
        coverpoint sequence_request.instr_dout {
            wildcard bins add_bin = {16'b0001_????????????};
            wildcard bins and_bin = {16'b0101_????????????};
            wildcard bins not_bin = {16'b1001_????????????};
            wildcard bins  ld_bin = {16'b0010_????????????};
            wildcard bins ldr_bin = {16'b0110_????????????};
            wildcard bins ldi_bin = {16'b1010_????????????};
            wildcard bins lea_bin = {16'b1110_????????????};
            wildcard bins  st_bin = {16'b0011_????????????};
            wildcard bins str_bin = {16'b0111_????????????};
            wildcard bins sti_bin = {16'b1011_????????????};
            wildcard bins  br_bin = {16'b0000_????????????};
            wildcard bins jmp_bin = {16'b1100_????????????};
        }
	endgroup : decode_in_cg
	
	function new(string name = "", uvm_component parent);
		super.new(name,parent);
		decode_in_cg = new();
	endfunction
	
	virtual function void write(T t);
		   `uvm_info("COVERAGE", {"Transaction received: ", t.convert2string()}, UVM_MEDIUM)
        counter += 1;  // Increment transaction counter
        `uvm_info("COVERAGE", $sformatf("Number of transactions received: %0d", counter), UVM_MEDIUM)

        sequence_request = t;  // Assign transaction to sample
        decode_in_cg.sample();  // Sample covergroup

	endfunction: write
endclass: decode_in_coverage