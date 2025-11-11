class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

  ncsu_component #(i2c_transaction) scoreboard;
  i2c_transaction temp_trans;
  i2c_transaction transport_trans;
  i2cmb_env_configuration configuration;

  //event strt;
  bit strt;
  bit stp;
  bit ack;
  int state;
  //event a_flg;
  //event stp;
  int rep_strt =0;

  T trans;
  bit write;
  bit read;
  
  //i2cmb_env_configuration configuration;
  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    temp_trans = new("temp_trans");
    transport_trans = new("transport_trans");
    strt = 0;
    stp = 0;
    transport_trans.data = new[1];
    //$display(" i am inside the scoreboard new function of scoreboard");
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
    //$display(" i am inside the set_configuration of predictor");
  endfunction

  virtual function void set_scoreboard(ncsu_component #(i2c_transaction) scoreboard);
      this.scoreboard = scoreboard;
      //$display(" i am inside the set_scoreboard of the predictor");
  endfunction

virtual function void nb_put(T trans);
  if ( trans.data == 8'b00000100 && trans.addr == 2'b10) begin
    strt = 1;
      //$display("my start is getting detetced");
    if (rep_strt != 0) // checking for the repeated start condition
    begin 
    //$display(" calling nb from start");
    //$display("data %d", trans.data);
      scoreboard.nb_transport(transport_trans, temp_trans);
    end

    rep_strt = rep_strt + 1;
    stp = 0;
  end

  if(strt ==1 && trans.addr == 2'b01 && ((trans.data == 8'b01000101) || (trans.data == 8'b01000100)) )
  begin
    if(trans.data[0] == 1)
    begin
      state = 2;
      //read =1;
      transport_trans.addr = trans.data[7:1]; // passing the values of slave address to the i2c transaction handle. LSB is used for detecting whether or not the operation is read / write
      ack = 1;
    end
    else
    begin
      state = 1;
      //write = 1;
      transport_trans.addr = trans.data[7:1];
      ack = 1;
    end
    strt =0; // start is being set to zero, for next transaction (n+1) the 
  end

  case(state)
    1: begin
        transport_trans.op = WRITE;
        if(trans.addr==2'b01 ) // data will be sent to the i2c from wb if the addr gets matched to dpr reg.
        begin
          //here the write data from the wb is getting passed onto the i2c 
          transport_trans.data[0] = trans.data;
          //write = 0;
        end
    end
    2: begin
        transport_trans.op = READ;
        if(trans.addr == 2'b01 )
        begin
          transport_trans.data[0] = trans.data;
          //read = 0;
        end
    end
  endcase

  if(trans.addr == 2'b10 && trans.data == 8'b00000101 )
  begin
   stp = 1;
   rep_strt=0;
   scoreboard.nb_transport(transport_trans,temp_trans);
  end
endfunction
endclass