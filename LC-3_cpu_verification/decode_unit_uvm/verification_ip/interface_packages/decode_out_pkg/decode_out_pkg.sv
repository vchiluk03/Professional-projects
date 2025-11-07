package decode_out_pkg;
    
    // Import UVM base package
    import uvm_pkg::*;
    
    // Include UVM macros
    `include "uvm_macros.svh"
    
    // Include the source files for the decode_out components
    `include "src/decode_out_sequence_item.svh"
    `include "src/decode_out_monitor.svh"
    `include "src/decode_out_configuration.svh"
    `include "src/decode_out_agent.svh"
    
endpackage: decode_out_pkg
