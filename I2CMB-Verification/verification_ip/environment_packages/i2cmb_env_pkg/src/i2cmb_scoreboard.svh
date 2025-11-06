
class i2cmb_scoreboard extends ncsu_component#(.T(i2c_transaction));

	T trans1;
	T trans_in;
	T trans_out;
  bit sc_bd;

  covergroup scbd_coverage_cg;
    option.per_instance = 1;
    score_mat: coverpoint sc_bd
    {
       //192 transactions in total, 32+32+64+64
      option.at_least = 192;
      bins sc_bd  = {1};
      //illegal_bins invalid_sc_bd= {0};
      
    }
  endgroup

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    scbd_coverage_cg = new;
  endfunction

  virtual function void nb_put(T trans);
    //$display({get_full_name()," nb_put: actual transaction ",trans.convert2string()});
	  trans_out = trans;
    scbd_coverage_cg.sample();
  /*if ( trans_in.compare(trans_out) ) 
    begin
      match = 1;
      $display({get_full_name()," i2c_transaction MATCH!"}); //fatal error near i2C_transaction class compare,
    end
    else
    begin               
      match =0;
      $display({get_full_name()," i2c_transaction MISMATCH!"});
    end
    scoreboard_coverage_cg.sample();*/
  endfunction
	
  virtual function void nb_transport(input T input_trans, output T output_trans);
    //$display({get_full_name()," nb_transport: expected transaction ",input_trans.convert2string()});
    this.trans_in = input_trans;
    output_trans = trans1;
    if ( trans_in.compare(trans_out) ) 
    begin
      sc_bd = 1;
      $display({get_full_name()," i2c_transaction MATCH!"});
      //scoreboard_coverage_cg.sample();
    end
    else                             
    begin  
      sc_bd = 0;
      $display({get_full_name()," i2c_transaction MISMATCH!"});
     //scoreboard_coverage_cg.sample();
    end
    scbd_coverage_cg.sample();
  endfunction
endclass


