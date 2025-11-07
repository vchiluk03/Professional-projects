package decode_test_pkg;

    // Import UVM base package
    import uvm_pkg::*;
    
    // Include UVM macros
    `include "uvm_macros.svh"
    
    // Import decode_in_pkg and decode_out_pkg
    import decode_in_pkg::*;
    import decode_out_pkg::*;
    import decode_env_pkg::*;
    
    // Include the test_top, which should instantiate both decode_in and decode_out agents
    `include "src/test_top.svh"

endpackage : decode_test_pkg
