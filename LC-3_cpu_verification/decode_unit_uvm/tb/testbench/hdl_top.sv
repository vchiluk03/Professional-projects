module hdl_top();

    // Importing UVM and the necessary packages
    import uvm_pkg::*;
    import decode_test_pkg::*;
    `include "uvm_macros.svh"
    
    // Signals for the testbench
    bit reset;
    bit clock;

    // decode_in signals
    wire [15:0] npc_in;
    wire [15:0] dout;
    wire enable_decode;
    wire [2:0] psr;

    // decode_out signals
    wire Mem_control;
    wire [1:0] W_control;
    wire [5:0] E_control;
    wire [15:0] IR;
    wire [15:0] npc_out;

    // Clock and reset logic
    initial begin 
        #15 reset = 1'b1;
        #25 reset = 1'b0;
     // Trigger the go event to start the BFM
        ->my_decode_out_monitor_bfm.go;
    end
    
    initial begin 
        clock = 0;
    end
    
    always #5 clock = ~clock;

    // Instantiate the decode_in interface and BFMs
    decode_in_if my_decode_in_intf(.clock(clock), .reset(reset));
    decode_in_driver_bfm my_decode_in_driver_bfm(my_decode_in_intf.driver);
    decode_in_monitor_bfm my_decode_in_monitor_bfm(my_decode_in_intf.monitor);

    // Instantiate the decode_out interface and BFMs
    decode_out_if my_decode_out_intf(.clock(clock), .reset(reset));
    decode_out_monitor_bfm my_decode_out_monitor_bfm(my_decode_out_intf.monitor);

// DUT (Design Under Test)
Decode DECODE_DUT(
    // Decode In interface connections (inputs to the DUT)
    .clock(my_decode_in_intf.clock),
    .reset(my_decode_in_intf.reset),
    .enable_decode(my_decode_in_intf.enable_decode),
    .npc_in(my_decode_in_intf.npc_in),
    .dout(my_decode_in_intf.instr_dout),

    // Decode Out interface connections (outputs from the DUT)
    .E_Control(my_decode_out_intf.E_Control),  // Connect decode_out interface
    .Mem_Control(my_decode_out_intf.Mem_Control),
    .W_Control(my_decode_out_intf.W_Control),
    .IR(my_decode_out_intf.IR),
    .npc_out(my_decode_out_intf.npc_out)
);

    // Configuring UVM to connect BFMs to the UVM environment
    initial begin
        // Setup for decode_in
        uvm_config_db#(virtual decode_in_driver_bfm)::set(null, "*", "decode_in_driver_bfm", my_decode_in_driver_bfm);
        uvm_config_db#(virtual decode_in_monitor_bfm)::set(null, "*", "decode_in_monitor_bfm", my_decode_in_monitor_bfm);
        uvm_config_db#(virtual decode_in_if)::set(null, "*", "decode_in_if", my_decode_in_intf);

        // Setup for decode_out
        uvm_config_db#(virtual decode_out_monitor_bfm)::set(null, "*", "decode_out_monitor_bfm", my_decode_out_monitor_bfm);
        uvm_config_db#(virtual decode_out_if)::set(null, "*", "decode_out_if", my_decode_out_intf);
    end

endmodule : hdl_top
