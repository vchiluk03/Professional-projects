import enumtype_i2c::*;

class i2c_transaction extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction)

       bit [6:0] addr;
       bit [7:0] data[];
       bit [7:0] r_data[];
       bit transfer_complete;
       i2c_op_t op;
       rand bit[7:0] random_i2c;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return {super.convert2string(),$sformatf("addr: %h data:%d transfer_complete : %d  op : %d", addr, data, transfer_complete, op)};
  endfunction

  function bit compare(i2c_transaction rhs);
    return ((this.addr  == rhs.addr ) && 
            (this.data == rhs.data)) &&
            ((this.op == rhs.op));
            
  endfunction

  virtual task i2c_set_read_data(bit [7:0] data[]);
    r_data[0] = data[0];
    //$display("i am inside the i2c_transaction r_data value is %d",r_data[0]);
  endtask
  
  virtual function void add_to_wave(int transaction_viewing_stream_h);
     super.add_to_wave(transaction_viewing_stream_h);
     $add_attribute(transaction_view_h,addr,"addr");
     $add_attribute(transaction_view_h,data,"data");
     $add_attribute(transaction_view_h,transfer_complete,"transfer_complete");
     $add_attribute(transaction_view_h,op,"op");
     $end_transaction(transaction_view_h,end_time);
     $free_transaction(transaction_view_h);
  endfunction

endclass
