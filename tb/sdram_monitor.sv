class sdram_monitor extends uvm_monitor;
	`uvm_component_utils(sdram_monitor)

	virtual sdram_if vif;
	uvm_analysis_port #(sdram_mon_item) ap;

	function new(string name = "sdram_monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap = new ("ap", this);
		if (!uvm_config_db#(virtual sdram_if)::get(this, "", "vif", vif))
			`uvm_fatal("BRAK VIF", "Monitor nie ma vif")
	endfunction

	task run_phase(uvm_phase phase);
		sdram_mon_item item;
		bit prev_cke = 1'b1;

		forever begin
			@(posedge vif.CLK);

			if (prev_cke == 1'b0) begin
				prev_cke = vif.CKE;
				continue;
			end
			prev_cke = vif.CKE;
			get_command();
		end
	endtask

	task get_command();
		sdram_mon_item mon_item;
		mon_item = sdram_mon_item::type_id::create("mon_item");

		mon_item.cs   = vif.CS;
        mon_item.ras  = vif.RAS;
        mon_item.cas  = vif.CAS;
        mon_item.we   = vif.WE;
        mon_item.cke  = vif.CKE;
        mon_item.ba   = vif.BA;
        mon_item.addr = vif.ADDR;
        mon_item.dq   = vif.DQ;
        mon_item.dqm  = vif.DQM;
        mon_item.curr_cmd = decode_cmd(mon_item.cs, mon_item.ras, mon_item.cas, mon_item.we, mon_item.cke);

        ap.write(mon_item);
        if (mon_item.curr_cmd != CMD_NOP) begin
        `uvm_info("MONITOR", $sformatf("%s  ba=%0d addr=%b dq=%h", mon_item.curr_cmd.name, 
        		   mon_item.ba, mon_item.addr, mon_item.dq), UVM_HIGH)
    	end
	endtask

    function sdram_cmd_e decode_cmd(bit cs, bit ras, bit cas, bit we, bit cke);
    	if (cs)      return CMD_INHIBIT;
    	casez ({ras, cas, we})
	        3'b111:  return CMD_NOP;
	        3'b011:  return CMD_ACTIVE;
	        3'b101:  return CMD_READ;
	        3'b100:  return CMD_WRITE;
	        3'b110:  return CMD_BURST_TERMINATE;
	        3'b010:  return CMD_PRECHARGE;
	        3'b001:  if (cke == 1'b1)
	        		 	return CMD_AUTO_REFRESH;
	        		 else return CMD_SELF_REFRESH;
	        3'b000:  return CMD_LOAD_MODE;
	        default: return CMD_UNKNOWN;
        endcase
    endfunction

endclass
