class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

    i2c_configuration configuration;
    i2c_op_t i2c_op;
    bit[6:0] i2c_addr;
    bit[7:0] i2c_read_data[];
    bit[7:0] i2c_write_data[];

    covergroup i2c_coverage_cg;
  	    option.per_instance = 1;
        option.name = get_full_name();

        i2c_op: coverpoint i2c_op
        {
            bins op_i2c={0,1};
        }

        i2c_addr: coverpoint i2c_addr
        {
            bins addr_i2c={34, 35};
        }

        i2c_read_data: coverpoint i2c_read_data[0]
        {
            bins read_data_i2c={[0:31], [63:0]};
        }

        i2c_write_data: coverpoint i2c_write_data[0]
        {
            bins write_data_i2c={[0:31], [64:127]};
        }

    endgroup


    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        i2c_coverage_cg = new;
        
    endfunction

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;

    endfunction

    virtual function void nb_put(T trans);
        i2c_read_data = new[1];
        i2c_write_data = new[1];
        i2c_addr = trans.addr;
        i2c_read_data = trans.data;
        i2c_write_data = trans.data;
        i2c_op = trans.op;
        i2c_coverage_cg.sample();
    endfunction
endclass