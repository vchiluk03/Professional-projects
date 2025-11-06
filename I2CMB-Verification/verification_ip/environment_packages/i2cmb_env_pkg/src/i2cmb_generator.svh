class i2cmb_generator extends ncsu_component;

    wb_transaction wb_tra;
    i2c_transaction i2c_tra;
    bit [7:0] i2c_read[];
    bit [7:0] temp_i2c_read;
    string wb_trans_name;
    string i2c_trans_name;
    bit [3:0] start;
    bit s_flag;
    bit x=0;
    bit[7:0]  z;
    

    //these are handles to the agents we are creating objects to the parent call
    ncsu_component #(wb_transaction) wb_age_hand;
    ncsu_component #(i2c_transaction) i2c_age_hand;

    function new (string name="", ncsu_component_base parent = null);
        super.new(name,parent);
        wb_tra = new("wb_tra");
        i2c_tra = new("i2c_tra");
    endfunction

    task cont_writes();  
        $display("############# 32 writes ##############");
        //enabling the core
        wb_tra.setting_data(2'b00,8'b11xxxxxx);
        wb_age_hand.mstr_write(wb_tra);
        //writing the ID of the desired bus into the DPR
        wb_tra.setting_data(2'b01,8'h05);
        wb_age_hand.mstr_write(wb_tra);
        //set bus command
        wb_tra.setting_data(2'b10,8'bxxxxx110);
        //at this line after writing to cmdr we have to check the don bit
        wb_age_hand.mstr_write(wb_tra);
        wb_age_hand.check_don_bit();
        for(int i=0; i<32; i++)
        begin
            //start command
            wb_tra.setting_data(2'b10,8'bxxxxx100);
            wb_age_hand.mstr_write(wb_tra);
            wb_age_hand.check_don_bit();
            check_start: 
            assert(wb_tra.addr == 2'b10 && wb_tra.data[2:0] == 3'h4) 
            else $error("start is not getting generated");
            //loading the address of the slave i.e 22 into the dpr
            wb_tra.setting_data(2'b01,8'b01000100);
            wb_age_hand.mstr_write(wb_tra);
            //write command
            wb_tra.setting_data(2'b10,8'bxxxxx001);
            wb_age_hand.mstr_write(wb_tra);
            wb_age_hand.check_don_bit();            
            //the data is getting written into the slave from 0 to 32
            wb_tra.setting_data(2'b01,i);
            wb_age_hand.mstr_write(wb_tra);
            //write command
            wb_tra.setting_data(2'b10,8'bxxxxx001);
            wb_age_hand.mstr_write(wb_tra);
            wb_age_hand.check_don_bit();
        end
        //stop command
        wb_tra.setting_data(2'b10,8'b00000101);
        wb_age_hand.mstr_write(wb_tra);
        wb_age_hand.check_don_bit();       
        wb_tra.setting_data(2'b00,x);
        wb_age_hand.mstr_read(wb_tra);
    endtask

    task cont_reads();
        $display("############# 32 reads #############");
        //enabling the core
        wb_tra.setting_data(2'b00,8'b11xxxxxx);
        wb_age_hand.mstr_write(wb_tra);
        //writing the ID of the desired bus into the DPR
        wb_tra.setting_data(2'b01,8'h05);
        wb_age_hand.mstr_write(wb_tra);
        //set bus command
        wb_tra.setting_data(2'b10,8'bxxxxx110);
        //at this line after writing to cmdr we have to check the don bit
        wb_age_hand.mstr_write(wb_tra);
        wb_age_hand.check_don_bit();
        //i2c_tra.r_data = new[1];
        i2c_tra.r_data = new[1];
        i2c_read = new[1];
        for(int i=0;i<32;i++)
        begin
            i2c_read[0] = i + 100;
            //$display("i2c_read data is : %d",i2c_read[i]);
            i2c_tra.i2c_set_read_data(i2c_read);
            //i2c_age_hand.bl_put(i2c_tra);
            //start command
            wb_tra.setting_data(2'b10,8'bxxxxx100);
            wb_age_hand.mstr_write(wb_tra);
            wb_age_hand.check_don_bit();
            //sending the slave address to dpr
            wb_tra.setting_data(2'b01,8'b01000101);
            wb_age_hand.mstr_write(wb_tra);
            //write command
            wb_tra.setting_data(2'b10,8'bxxxxx001);
            wb_age_hand.mstr_write(wb_tra);
            wb_age_hand.check_don_bit();
            //read with nak command
            wb_tra.setting_data(2'b10,8'bxxxxx011);
            wb_age_hand.mstr_write(wb_tra);
            wb_age_hand.check_don_bit();
            wb_tra.setting_data(2'b01,temp_i2c_read);
            wb_age_hand.mstr_read(wb_tra);
        end
         //stop command
        wb_tra.setting_data(2'b10,8'b00000101);
        wb_age_hand.mstr_write(wb_tra);
        wb_age_hand.check_don_bit();
        wb_tra.setting_data(2'b11,x);
        wb_age_hand.mstr_read(wb_tra);
    endtask

    task alt_rd_wr ();
        $display("############# alternates 32 reads  and 32 writes #############");
        //enabling the core
        wb_tra.setting_data(2'b00,8'b11xxxxxx);
        wb_age_hand.bl_put(wb_tra);
        //writing the ID of the desired bus into the DPR
        wb_tra.setting_data(2'b01,8'h05);
        wb_age_hand.mstr_write(wb_tra);
        //set bus command
        wb_tra.setting_data(2'b10,8'bxxxxx110);
        //at this line after writing to cmdr we have to check the don bit
        wb_age_hand.mstr_write(wb_tra);
        wb_age_hand.check_don_bit();
        for(int i=0;i<64;i++)
            begin
                 //start command
                wb_tra.setting_data(2'b10,8'bxxxxx100);
                wb_age_hand.mstr_write(wb_tra);
                wb_age_hand.check_don_bit();
                //loading the address of the slave i.e 22 into the dpr
                wb_tra.setting_data(2'b01,8'b01000100);
                wb_age_hand.mstr_write(wb_tra);
                //write command
                wb_tra.setting_data(2'b10,8'bxxxxx001);
                wb_age_hand.mstr_write(wb_tra);
                wb_age_hand.check_don_bit();
                //the data is getting written into the slave from 0 to 32
                wb_tra.setting_data(2'b01,i+64);
                wb_age_hand.mstr_write(wb_tra);
                //write command
                wb_tra.setting_data(2'b10,8'bxxxxx001);
                wb_age_hand.mstr_write(wb_tra);
                wb_age_hand.check_don_bit();
                i2c_read[0] = 63-i;
                i2c_tra.i2c_set_read_data(i2c_read);
                //i2c_age_hand.bl_put(i2c_tra);
                //start command
                wb_tra.setting_data(2'b10,8'bxxxxx100);
                wb_age_hand.mstr_write(wb_tra);
                wb_age_hand.check_don_bit();
                //sending the slave address to dpr
                wb_tra.setting_data(2'b01,8'b01000101);
                wb_age_hand.mstr_write(wb_tra);
                //write command
                wb_tra.setting_data(2'b10,8'bxxxxx001);
                wb_age_hand.mstr_write(wb_tra);
                wb_age_hand.check_don_bit();
                //read with nak command
                wb_tra.setting_data(2'b10,8'bxxxxx011);
                wb_age_hand.mstr_write(wb_tra);
                wb_age_hand.check_don_bit();
                wb_tra.setting_data(2'b01,temp_i2c_read);
                wb_age_hand.mstr_read(wb_tra);
            end
        //stop command
        wb_tra.setting_data(2'b10,8'b00000101);
        wb_age_hand.mstr_write(wb_tra);
        wb_age_hand.check_don_bit();
    endtask

virtual task run();
    fork
        wbrun();
        i2crun();
    join
    disable fork;
endtask

task wbrun();
    wb_trans_name = "wb_transaction";
    $cast(wb_tra,ncsu_object_factory::create(wb_trans_name));
    cont_writes();
    cont_reads();
    alt_rd_wr ();
endtask

task i2crun();
    for(int i=0;i<31;i++)
    begin
        i2c_age_hand.bl_put(i2c_tra);
    end

    for(int i=0;i<64;i++)
    begin
        i2c_age_hand.bl_put(i2c_tra);
    end
endtask
    
virtual task rw_wr_per_field();
    wb_tra.setting_data(2'b00,8'b00xxxxxx);
    wb_age_hand.mstr_write(wb_tra);
    $display("****************** testing read write permission started ***************");
    wb_tra.setting_data(2'b00,8'b11111111); //enable core, deliberatly writing into the readonly bits in CSR, if the readonly bits store the values of 1, then it will be an error
                                            // readonly bits should not let us to write bits into them.    
    wb_age_hand.mstr_write(wb_tra);
    wb_age_hand.mstr_read(wb_tra);
    if((wb_tra.addr == 2'b00) && (wb_tra.data != 8'b11000000))  // other than 8th and 7th bit (LSBs) other all bits should be 0's. If all other bits are not zeros then read only bits are getting accessed, which is error.
        $error("Bits confined for RO are being written now, error");
endtask


virtual task check_default_values();  
    $display(" ****************** test register default values started ****************");
    wb_tra.setting_data(2'b00,8'b00xxxxxx);
    wb_age_hand.mstr_write(wb_tra);
    wb_tra.setting_data(2'b00,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    
    if(wb_tra.data != 0 ) 
        $error(" default value gone wrong, error in csr default value");

    wb_tra.setting_data(2'b01,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.data != 0 )
        $error(" default value gone wrong, error in dpr default value");

    wb_tra.setting_data(2'b10,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.data != 128 )
        $error(" default value gone wrong, error in cmdr default value");

    wb_tra.setting_data(2'b11,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.data != 0 )
        $error(" default value gone wrong, error in fsmr default value");

    wb_tra.setting_data(2'b00,8'b11xxxxxx);
    wb_age_hand.mstr_write(wb_tra);
endtask        

virtual task fsmr_check  ();
    int i;
    $display(" **************test for fsmr_check ******************");  
    wb_tra.setting_data(2'b00,8'b11xxxxxx);
    wb_age_hand.mstr_write(wb_tra);
    wb_tra.setting_data(2'b01,8'bxxxxx101); 
    wb_age_hand.mstr_write(wb_tra);
    wb_tra.setting_data(2'b10,8'bxxxxx110);
    wb_age_hand.mstr_write(wb_tra);
    wb_age_hand.check_don_bit();
    wb_tra.setting_data(2'b11,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.addr == 2'b11 && wb_tra.data[7:4] != 4'b0000)
        $error(" done bit is not getting set correctly, error!!");
    wb_tra.setting_data(2'b10,8'bxxxxx100);
    wb_age_hand.mstr_write(wb_tra);
    wb_age_hand.check_don_bit();    
    wb_tra.setting_data(2'b11,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.addr == 2'b11 && wb_tra.data[7:4] != 4'b0001)        
        $error("nack bit is not getting set correctly, error !!");
    //$display("************test for fsmr check is done****************");
endtask


virtual task regfield_aliasing_test();
    $display("**************regfield_alias_test***************");
    wb_tra.setting_data(2'b00,8'b11xxxxxx);
    wb_age_hand.mstr_write(wb_tra);
    //writing the values 01010101 into theDPR register and checking the values in other registers, other registers should not get this data.
    wb_tra.setting_data(2'b01,8'b01010101);
    wb_age_hand.mstr_write(wb_tra);
    wb_tra.setting_data(2'b10,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.addr == 2'b10 && wb_tra.data == 8'b01010101)
        $error(" this data has been sent to DPR, but shouldn't be reflecting in cmdr, Error!!!!");
    wb_tra.setting_data(2'b00,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.addr == 2'b00 && wb_tra.data == 8'b01010101)
        $error(" this data has been sent to DPR, but shouldn't be reflecting in csr, Error!!!!");
    wb_tra.setting_data(2'b10,wb_tra.data);
    wb_age_hand.mstr_read(wb_tra);
    if(wb_tra.addr == 2'b11 && wb_tra.data == 8'b01010101)
        $error(" this data has been sent to DPR, but shouldn't be reflecting in fsmr, Error!!!!");
endtask

function void set_wb_agent(ncsu_component #(.T(wb_transaction)) agent);
      this.wb_age_hand = agent;
endfunction

function void set_i2c_agent(ncsu_component #(.T(i2c_transaction)) agent);
      this.i2c_age_hand = agent;
endfunction
endclass









        





















        

        



