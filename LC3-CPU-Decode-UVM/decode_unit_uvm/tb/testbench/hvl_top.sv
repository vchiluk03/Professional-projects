module hvl_top();

    // Import UVM and necessary packages
    import uvm_pkg::*;
    import decode_test_pkg::*;
    `include "uvm_macros.svh"

    // Import both decode_in and decode_out packages
    import decode_in_pkg::*;
    import decode_out_pkg::*;
    
    //import lc3_prediction_pkg::*;
    import decode_env_pkg::*;
    // Initial block to run the test
    initial begin
        // Run the UVM test
        run_test("test_top");
    end

endmodule : hvl_top
