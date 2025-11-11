class i2cmb_coverage extends ncsu_component#(.T(wb_transaction));

    i2cmb_env_configuration     configuration;
    
    bit[7:0] i2cmb_write_data;
    bit[7:0] i2cmb_read_data;
    bit[1:0] wb_addr;
    bit[1:0] val_reg_addr;
    bit[1:0] acc_reg;
    bit[7:0] def_reg;
    bit ch_don_bit;
    bit [2:0] reg_set;
    bit [2:0] reg_val_cmd;
    bit [7:0] reg_defa_val;
    bit reg_rw;
    bit[1:0] register;
    bit[3:0] wait_fsmr;
    bit[3:0] start_fsmr;
    bit[3:0] stop_fsmr;
    bit s_flag;
    bit ch_IE;
    bit ch_E;


    covergroup byte_fsmr_covergroup_cg;
        option.per_instance=1;
        option.name = get_full_name();

        wait_fsmr: coverpoint wait_fsmr
        {
            bins wait_fsmr ={4'b0000};
        }
        start_fsmr: coverpoint start_fsmr
        {
            bins start_fsmr = {4'b0011};
        }
        stop_fsmr: coverpoint stop_fsmr
        {
            bins stop_fsmr = {4'b0100};
        }
    endgroup

    covergroup reg_tst_coverage_cg;
        option.per_instance=1;
        option.name = get_full_name();

        val_reg_addr: coverpoint val_reg_addr
        {   
            bins val = {0,1,2,3};
        }
        reg_dft_val: coverpoint reg_defa_val
        {
            option.auto_bin_max = 0;
            bins def_reg_val = {0};
        }
        reg_set: coverpoint reg_set
        {
            bins reg_set = {3'b110};
            //illegal_bins wrong_setbus = {3'b000,3'b001,3'b010,3'b011,3'b100,3'b101};
        }
        reg_val_cmd: coverpoint reg_val_cmd
        {
            bins reg_val = {[0:6]};
        }
        reg_rw: coverpoint reg_rw
        {
            bins r = {0};
            bins w = {1};
        }
        register:coverpoint register
        {
            bins fsmr = {2'b11};
            bins csr = {2'b00};
            bins dpr = {2'b01};
            bins cmdr = {2'b10};  
        }
        default_check: cross register, reg_dft_val
        {
        
        }
        reg_r_w_per: cross  register, reg_rw
        {
            bins csr_rw_per = binsof(register.csr) && binsof(reg_rw.r) && binsof(reg_rw.w);
            bins fsmr_rw_per = binsof(register.fsmr) && binsof(reg_rw.r);
            bins dpr_rw_per = binsof(register.dpr) && binsof(reg_rw.r) && binsof(reg_rw.w);
            illegal_bins fsmr_invalid_rw_per = binsof(register.fsmr) && binsof(reg_rw.w);
            bins cmdr_rw_per = binsof(register.cmdr) && binsof(reg_rw.r) && binsof(reg_rw.w);
        }
    endgroup

    covergroup i2cmb_coverage_cg;
  	    option.per_instance = 1;
        option.name = get_full_name();

        i2cmb_write_data: coverpoint i2cmb_write_data
        {
            bins write_data_i2cmb = {[0:31], [64:127]};
        }
        i2cmb_read_data: coverpoint i2cmb_read_data
        {
            bins read_data_i2cmb = {[100:131], [63:0]};
        }
        wb_addr: coverpoint wb_addr
        {
            bins addr_wb = {2'b00,2'b01,2'b10};
        }
        ch_don_bit: coverpoint ch_don_bit
        {
            bins don_bit = {1};
        }
        ch_IE: coverpoint ch_IE
        {
            bins ch_IE = {1};

        }
        ch_E: coverpoint ch_E
        {
            bins ch_E = {1};
        }
    endgroup

    function void set_configuration(i2cmb_env_configuration cfg);
        configuration = cfg;
    endfunction

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        reg_tst_coverage_cg = new;
        i2cmb_coverage_cg = new;
        //byte_fsmr_covergroup_cg = new;     
    endfunction

    virtual function void nb_put(T trans);
        i2cmb_read_data = trans.data;
        i2cmb_write_data = trans.data;
        register = trans.addr;
        reg_rw = trans.we;
        wb_addr = trans.addr;
        val_reg_addr = trans.addr;

        if(trans.addr == 2'b00) begin
            ch_IE = trans.data[6];
            ch_E = trans.data[7];
        end

        if(trans.addr == 2'b10) ch_don_bit=trans.data[7];

        if(trans.addr == 2'b10) reg_val_cmd = trans.data[2:0];   

        if(register == 2'b10 ) reg_set = trans.data[2:0];

        if(trans.addr == 2'b11) begin
            wait_fsmr = trans.data[7:4];
            stop_fsmr = trans.data[7:4];
        end

        if((trans.we == 0)) reg_defa_val = trans.data;

        if(trans.addr == 2'b10 && trans.data == 8'b100) s_flag = 1;

       if(trans.addr == 2'b11 && s_flag == 1) begin
            start_fsmr = trans.data[7:4];
            s_flag=0;
        end

        reg_tst_coverage_cg.sample();
        i2cmb_coverage_cg.sample();    
    endfunction

endclass

