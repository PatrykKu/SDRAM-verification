class sdram_coverage extends uvm_subscriber #(sdram_mon_item);
	`uvm_component_utils(sdram_coverage)

	sdram_mon_item curr_mon_item;
	sdram_cmd_e    curr_cmd;

	covergroup cg_commands with function sample (sdram_cmd_e cmd, bit [11:0] addr, bit cke);

		c_cmd: coverpoint cmd{
			bins commandInhibit = {CMD_INHIBIT};
			bins nop = {CMD_NOP};
			bins active = {CMD_ACTIVE};
			bins read = {CMD_READ};
			bins write = {CMD_WRITE};
			bins precharge = {CMD_PRECHARGE};
			bins selfRefresh = {CMD_SELF_REFRESH};
			bins autoRefresh = {CMD_AUTO_REFRESH};
			bins loadModeRegister = {CMD_LOAD_MODE};

			bins init = (CMD_PRECHARGE => CMD_NOP[*2] => CMD_AUTO_REFRESH => CMD_NOP[*9] => CMD_AUTO_REFRESH => CMD_NOP[*9]);
			bins prepareMemory = (CMD_LOAD_MODE => CMD_NOP[*2] => CMD_ACTIVE => CMD_NOP[*2]);
			bins write_trans = (CMD_WRITE => CMD_NOP);
			bins read_trans = (CMD_READ => CMD_NOP);
		}

		c_auto_precharge: coverpoint addr[10] iff(curr_cmd == CMD_WRITE || curr_cmd == CMD_READ){
			bins auto_precharge    = {1'b1};
			bins no_auto_precharge = {1'b0};
		}

		c_cke: coverpoint cke{
			bins cke_high    = {1'b1};
			bins cke_low     = {1'b0};
			bins enter_sleep = (1'b1 => 1'b0);
			bins exit_sleep  = (1'b0 => 1'b1);			
		}

		cx_rw_precharge: cross c_cmd, c_auto_precharge {
    		ignore_bins ignore_other_cmds = !binsof(c_cmd.read) && !binsof(c_cmd.write);
		}

	endgroup

	covergroup cg_mode_register with function sample (bit [11:0] addr);

		c_burstLength: coverpoint addr[2:0] iff (curr_cmd == CMD_LOAD_MODE) {
			bins bytes1   = {3'b000};
			bins bytes2   = {3'b001};
			bins bytes4   = {3'b010};
			bins bytes8   = {3'b011};
			bins fullPage = {3'b111};
		}

		c_burstType: coverpoint addr[3] iff (curr_cmd == CMD_LOAD_MODE){
			bins sequential  = {0};
			bins interleaved = {1};
		}

		c_cas: coverpoint addr[6:4] iff (curr_cmd == CMD_LOAD_MODE){
			bins cas2  = {3'b010};
			bins cas3  = {3'b011};
		}

		c_opMode: coverpoint addr[8:7] iff (curr_cmd == CMD_LOAD_MODE){
			bins standard = {2'b00};
		}

		c_wbMode: coverpoint addr[9] iff (curr_cmd == CMD_LOAD_MODE){
			bins programed      = {0};
			bins singleLocation = {1};
		}

		cx_length_type: cross c_burstLength, c_burstType {
			ignore_bins fp_interleaved = binsof(c_burstLength.fullPage) && 
                                         binsof(c_burstType.interleaved);
		}

		cx_entire_lmr: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins fp_interleaved_wb  = binsof(c_burstLength.fullPage) && (
                                             binsof(c_burstType.interleaved) || 
                                             binsof(c_wbMode.singleLocation)
                                             );
		}

	endgroup

	covergroup cg_data with function sample (bit [15:0] dq, bit [1:0] dqm);
		c_data: coverpoint dq iff (curr_cmd == CMD_WRITE || curr_cmd == CMD_READ) {
			bins zeroes      = {16'h0000};
			bins ones 	     = {16'hFFFF};
			bins zeroes_ones = {16'h5555};
			bins ones_zeroes = {16'hAAAA};

			bins lower_half[16] = {[16'h0001:16'h7FFF]};
			bins upper_half[16] = {[16'h8000:16'hFFFE]};

			bins walking_one[] = { 
		        16'h0001, 16'h0002, 16'h0004, 16'h0008,
		        16'h0010, 16'h0020, 16'h0040, 16'h0080,
		        16'h0100, 16'h0200, 16'h0400, 16'h0800,
		        16'h1000, 16'h2000, 16'h4000, 16'h8000
   		    };
   		}

   		c_byte_mask: coverpoint dqm iff (curr_cmd == CMD_WRITE || curr_cmd == CMD_READ || curr_cmd == CMD_NOP) {
   			bins masks [4] = {2'b00, 2'b01, 2'b10, 2'b11};
   			}


		
	endgroup

	covergroup cg_addressing with function sample (bit [1:0] ba, bit [11:0] addr);

		c_bank_rows: coverpoint ba iff(curr_cmd == CMD_ACTIVE) {
			bins banks[4] = {2'b00, 2'b01, 2'b10, 2'b11};
		}

		c_bank_columns_write: coverpoint ba iff(curr_cmd == CMD_WRITE) {
			bins banks[4] = {2'b00, 2'b01, 2'b10, 2'b11};
		}

		c_bank_columns_read: coverpoint ba iff(curr_cmd == CMD_READ) {
			bins banks[4] = {2'b00, 2'b01, 2'b10, 2'b11};
		}

		c_rows: coverpoint addr iff(curr_cmd == CMD_ACTIVE){
			bins zeroes = {12'h000};
			bins ones   = {12'hFFF};

			bins allrows[21] = {[12'h001:12'hFFE]};
		}

	    c_columns_write: coverpoint addr[8:0] iff(curr_cmd == CMD_WRITE){
			bins zeroes = {9'h000};
			bins ones   = {9'h1FF};

			bins allcolumns[11] = {[9'h001:9'h1FE]};
		}

	    c_columns_read: coverpoint addr[8:0] iff(curr_cmd == CMD_READ){
			bins zeroes = {9'h000};
			bins ones   = {9'h1FF};

			bins allcolumns[11] = {[9'h001:9'h1FE]};
		}

		c_bank_interleaving: coverpoint ba iff(curr_cmd == CMD_ACTIVE) {
			bins bank0_others[] = (2'b00 => 2'b01, 2'b10, 2'b11);
			bins bank1_others[] = (2'b01 => 2'b00, 2'b10, 2'b11);
			bins bank2_others[] = (2'b10 => 2'b00, 2'b01, 2'b11);
			bins bank3_others[] = (2'b11 => 2'b00, 2'b01, 2'b10);
		}

		cx_active_row: cross c_bank_rows, c_rows;
		cx_write_column: cross c_bank_columns_write, c_columns_write;
		cx_read_column: cross c_bank_columns_read, c_columns_read;
	endgroup


	  function new(string name, uvm_component parent);
	    super.new(name, parent);
	    cg_commands      = new();
	    cg_mode_register = new();
	    cg_data          = new();
	    cg_addressing    = new();
	  endfunction

	  function void write(sdram_mon_item t);
	    curr_mon_item = t;
	    curr_cmd      = t.curr_cmd;

	    cg_commands.sample(curr_cmd, t.addr, t.cke);
    	cg_mode_register.sample(t.addr);
    	cg_data.sample(t.dq, t.dqm);
    	cg_addressing.sample(t.ba, t.addr);
	  endfunction

	  function void report_phase(uvm_phase phase);
	    `uvm_info(get_type_name(),
	      $sformatf("Coverage komend: %.2f%%", cg_commands.get_coverage()), UVM_LOW)

	    `uvm_info(get_type_name(),
	      $sformatf("Coverage LMR: %.2f%%", cg_mode_register.get_coverage()), UVM_LOW)

	    `uvm_info(get_type_name(),
	      $sformatf("Coverage data: %.2f%%", cg_data.get_coverage()), UVM_LOW)

	    `uvm_info(get_type_name(),
	      $sformatf("Coverage adresowania: %.2f%%", cg_addressing.get_coverage()), UVM_LOW)
	  endfunction

endclass