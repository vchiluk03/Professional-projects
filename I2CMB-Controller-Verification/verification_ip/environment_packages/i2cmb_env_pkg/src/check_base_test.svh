class check_base_test extends ncsu_component#(.T(wb_transaction));
    
    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

endclass