onerror resume
wave tags  sim
wave update off
wave zoom range 0 495
wave group hdl_top.DECODE_DUT -backgroundcolor #004466
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.clock -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.reset -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.enable_decode -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.dout -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.npc_in -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.Mem_Control -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.E_Control -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.W_Control -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.M_Control -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.inst_type -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.pc_store -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.mem_access_mode -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.load -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.pcselect1 -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.alu_control -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.pcselect2 -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.op2select -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.IR -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.npc_out -tag sim -radix hexadecimal -select
wave add -group hdl_top.DECODE_DUT hdl_top.DECODE_DUT.opcode -tag sim -radix hexadecimal -select
wave insertion [expr [wave index insertpoint] + 1]
wave update on
wave top 0
