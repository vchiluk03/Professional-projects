`timescale 1ns / 10ps
import enumtype_i2c:: * ;
import ncsu_pkg::*;
import i2c_pkg::*;
import wb_pkg::*;
import i2cmb_env_pkg::*;

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

parameter int i2c_ADDR_WIDTH = 7;
parameter int i2c_DATA_WIDTH = 8;

bit  clk;
parameter int period = 10;
bit  rst = 1'b1;
wire cyc;
wire stb;
bit we;
bit write_enable;
tri1 ack;
logic [WB_ADDR_WIDTH-1:0] adr;
logic [WB_ADDR_WIDTH-1:0] adr_wb;
logic [WB_DATA_WIDTH-1:0] dat_wr_o;
logic [WB_DATA_WIDTH-1:0] dat_wb;
logic [WB_DATA_WIDTH-1:0] dat_rd_i;

bit [i2c_ADDR_WIDTH-1:0] i2c_adrm;
bit [i2c_DATA_WIDTH-1:0] i2c_drm[];
i2c_op_t op_i2c_monitor;

bit [i2c_DATA_WIDTH-1:0] read[];
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;
i2c_op_t  op;
bit wb_write = 0;
bit read_compl;
bit [7:0] temp_read;
int j=0;
int x;

i2cmb_test tst;
// ****************************************************************************
// Clock generator
initial
begin : clk_gen
 forever #(period/2) clk=~clk;
end: clk_gen

// ****************************************************************************
// Reset generator
initial 
begin : rst_gen
#113ns; 
rst = 1'b0;
end: rst_gen

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model

wb_if #(
			 .ADDR_WIDTH(WB_ADDR_WIDTH),
             .DATA_WIDTH(WB_DATA_WIDTH)
            )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  .irq_i(irq),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );
 
// ***********************************************************************************
//instantiating the i2c slave bus functional model

i2c_if #(.ADDR_WIDTH(i2c_ADDR_WIDTH),.I2C_DATA_WIDTH(i2c_DATA_WIDTH))		

i2c_bus (
	//system signals
	.scl(scl),
	.sda_i(sda)
	);


// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

   
   
initial begin
    
    ncsu_config_db#(virtual wb_if)::set("tst.env.wb_age", wb_bus);
    ncsu_config_db#(virtual i2c_if)::set("tst.env.i2c_age", i2c_bus);
    
    tst = new("tst",null);
    wait ( rst == 1);
    
    tst.run(); 
    #100ns;
    $finish();
  end



endmodule
