interface decode_out_if 
  (
  input wire clock, 
  input wire reset
  );

  // Signal declaration
  logic [15:0] IR;
  logic [5:0] E_Control;
  logic [15:0] npc_out;
  logic Mem_Control;
  logic [1:0] W_Control;
  logic enable_decode_out;

  // Modport for the passive driver (just listens, no outputs)
  modport driver 
    (
    input clock,
    input reset,
    input IR,
    input E_Control,
    input npc_out,
    input Mem_Control,
    input W_Control,
    input enable_decode_out
    );

  // Modport for the monitor (also just listens, like the driver)
  modport monitor 
    (
    input clock,
    input reset,
    input IR,
    input E_Control,
    input npc_out,
    input Mem_Control,
    input W_Control,
    input enable_decode_out
    );

endinterface
