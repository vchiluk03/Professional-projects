`timescale 1ns / 10ps
import enumtype_i2c:: *;

interface i2c_if #(
      int ADDR_WIDTH = 7,                                
      int I2C_DATA_WIDTH = 8                                
      )
	  
(
  // i2c sigals
  inout triand sda_i,
  input tri scl
);
 
  bit strt; 
  bit stp;
  int i;
  int j;
  bit [6:0] temp;
  bit rw;
  bit ctrl_mstr = 1; // master variable for telling the control is with master
  bit ctrl_slave;    //slave variable for telling the control is in slaves's hand
  bit temp_data_unpacked[8];
  bit mon_temp_unpack[8];

  initial begin
   strt =0; 
   stp =0;
   i=0;
   j=0;
  end
  
  assign sda_i  = ctrl_mstr ? 1'bz : ctrl_slave;   // sda_i is a wire, it doesn't hold any kind of memory, using assign statement we are keeping the line to zero whenever there is an acknowledgment.

 
always@(negedge sda_i)  begin // start condition capturing.
	if(scl == 1) begin 
		strt = 1;
		stp = 0;
	end
end

always@(posedge sda_i) begin// stop condition capturing
	if(scl == 1)begin     
  		stp = 1;
		strt = 0;
	end
end
 
task wait_for_i2c_transfer (
	output i2c_op_t op,
	output bit [I2C_DATA_WIDTH-1:0] write_data []
);
	//$display("I am inside the I2C interface first line");

	bit [6:0] temp;
	bit [6:0] slv_addr;

	write_data = new[1];

	//$display("I am inside the I2C interface first line");
	// Waiting here until the start gets captured.
	wait (strt);

	//$display("I am just after the wait for strt in I2C interface");
	#1 strt = 0; // Make start = 0 to capture the next start for next transfer

	// Burning the clock for 7 cycles to get the address
	//$display("Burning the clock for 7 times to get the last bit values");
	repeat (7) begin
		@(posedge scl) slv_addr[i] = sda_i;
		i++;
		//$display("I am inside the repeat statement");
	end

	//$display("Burning the clock is done");

	// Checking whether the last bit is 0 or 1 — determines R/W operation
	@(posedge scl) rw = sda_i;

	//$display("Checking whether the last bit is 0 or 1");

	// Slave giving the ACK
	@(negedge scl) begin
		ctrl_mstr  = 0;
		ctrl_slave = 0;
	end

	//$display("Slave has given the acknowledgment");

	if (rw == 1) begin
		op = READ;
		return;
	end
	else begin
		op = WRITE;

		// Giving back control to master for writing data
		@(negedge scl) ctrl_mstr = 1;

		//$display("I am in the middle of I2C interface, op assigned to WRITE");

		// Continuously checking for start or stop while data transfers
		fork
			begin
				repeat (8) begin
					@(posedge scl) write_data = {write_data, sda_i};
				end

				// After transferring 8 bits, slave gives ACK
				@(negedge scl) begin
					ctrl_mstr  = 0;
					ctrl_slave = 0;
					@(negedge scl) ctrl_mstr = 1;
				end
			end

			begin
				wait (strt || stp);
			end
		join_any

		// If any one process completes, disable fork
		disable fork;
	end

	//$display("I am at the end of I2C interface");
endtask

	

task provide_read_data (
	input  bit [I2C_DATA_WIDTH-1:0] read_data [],
	output bit transfer_complete
);
	// Data sent by the master for reading is an unpacked array of packed bits.
	// We will put the data bit by bit on the SDA line, for this we need to unpack the array.

	for (int i = 0; i < read_data.size(); i++) begin
		// Unpacking
		{>>{temp_data_unpacked}} = read_data[i];

		foreach (temp_data_unpacked[j]) begin
			@(negedge scl) ctrl_slave = temp_data_unpacked[j];
		end

		// Control given to the master for acknowledgment
		@(negedge scl) ctrl_mstr = 1;

		@(posedge scl);
		begin
			// If SDA line is low (ACK), master wants more data from slave
			if (sda_i == 0) begin
				ctrl_mstr  = 0;
				ctrl_slave = 0;
				//$display("Control is with slave — master requests more data");
			end
			else begin
				// If SDA == 1 (NACK), stop the read transfer
				ctrl_mstr = 1;
				//$display("Master does not want further data — stopping read");
				break;
			end
		end
	end

	// Wait for start or stop condition to ensure proper transaction end
	wait (strt || stp);

	// Indicates read operation is complete
	transfer_complete = 1;
endtask


task monitor (
	output bit [ADDR_WIDTH-1:0] addr,
	output i2c_op_t op,
	output bit [I2C_DATA_WIDTH-1:0] data []
);
	bit rw;
	bit [7:0] t_data;
	data = new[1];

	// Wait for start condition and clear it
	wait (strt);
	#1 strt = 0;

	// Capture 7-bit address from SDA line
	repeat (7) begin
		@(posedge scl) addr = {addr, sda_i};
	end

	// Capture R/W bit (1 = read, 0 = write)
	@(posedge scl) rw = sda_i;

	// Extra clock: slave gives ACK indicating address received
	@(posedge scl);
	ack_check:
	assert (sda_i == 0)
	else $error("Acknowledgment not received after address phase");

	if (rw == 0) begin
		// -------------------------------
		// Write operation from master
		// -------------------------------
		op = WRITE;

		// Continuously check for start or stop command during data write
		fork
			begin
				repeat (8) begin
					@(posedge scl) t_data = {t_data, sda_i};
				end
				data[0] = '{t_data};
				@(posedge scl); // Wait for ACK clock
			end

			begin
				wait (strt || stp); // Wait for repeated start or stop
			end
		join_any
		disable fork;
	end
	else begin
		// -------------------------------
		// Read operation from slave
		// -------------------------------
		op = READ;

		// Capture data bits during read phase
		repeat (8) begin
			@(posedge scl) t_data = {t_data, sda_i};
		end

		data[0] = '{t_data};

		// Burn one clock cycle to allow ACK from master
		@(posedge scl);
	end
endtask

endinterface
