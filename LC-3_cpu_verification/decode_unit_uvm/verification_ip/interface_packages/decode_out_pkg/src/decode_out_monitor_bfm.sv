interface decode_out_monitor_bfm (decode_out_if bus);

  import decode_out_pkg::*;

  decode_out_pkg::decode_out_monitor monitor;
  // This connects to the actual monitor instance.

  event go;

  // Task to observe the signals on the bus (decode_out_if)
  task monitor_task(output logic [15:0] IR_m, 
                    output logic [5:0] E_Control_m, 
                    output logic [15:0] npc_out_m,
                    output logic Mem_Control_m,
                    output logic [1:0] W_Control_m,
                    output logic enable_decode_out_m
                   );

    // Sample the signals from the bus (interface)
    IR_m = bus.IR;
    E_Control_m = bus.E_Control;
    npc_out_m = bus.npc_out;
    Mem_Control_m = bus.Mem_Control;
    W_Control_m = bus.W_Control;
    enable_decode_out_m = bus.enable_decode_out;

  endtask: monitor_task

  // Main monitoring process
  initial begin
    @go  // Wait for the 'go' signal to start
    forever begin
      logic [15:0] IR;
      logic [5:0] E_Control;
      logic [15:0] npc_out;
      logic Mem_Control;
      logic [1:0] W_Control;
      logic enable_decode_out;

      @(posedge bus.clock);  // Wait for the clock edge

      // Call the task to monitor the bus signals
      monitor_task(IR, E_Control, npc_out, Mem_Control, W_Control, enable_decode_out);

      // Notify the monitor with the collected transaction
      monitor.collect_transaction(IR, E_Control, npc_out, Mem_Control, W_Control, enable_decode_out);
    end
  end

endinterface: decode_out_monitor_bfm

