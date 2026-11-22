class sdram_coverage_ddor extends uvm_subscriber #(sdram_mon_item);
	`uvm_component_utils(sdram_coverage_ddor)

	sdram_mon_item curr_mon_item;
	sdram_cmd_e    curr_cmd;
	sdram_cfg      cfg;

	covergroup cg_commands with function sample (sdram_cmd_e cmd, bit [11:0] addr, bit cke, test_e curr_test);

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
		}

		c_op: coverpoint cmd{
			bins init = (CMD_PRECHARGE => CMD_NOP[*2] => CMD_AUTO_REFRESH => CMD_NOP[*9] => CMD_AUTO_REFRESH => CMD_NOP[*9]);
			bins prepareMemory = (CMD_LOAD_MODE => CMD_NOP[*2] => CMD_ACTIVE => CMD_NOP[*2]);
			bins write_trans = (CMD_WRITE => CMD_NOP);
			bins read_trans = (CMD_READ => CMD_NOP);
		}

		c_rw: coverpoint curr_test{
			bins trans[] = {TEST_BURST_RW_AP, TEST_BURST_RW_NP};
		}

		c_highz: coverpoint curr_test{
		    bins highz[] = {TEST_BURST_RW_AP_HZ, TEST_BURST_RW_NP_HZ};
		}

		c_full_page: coverpoint curr_test{
			bins fullpage = {TEST_FULL_PAGE_RW_NP};
		}

		c_trunc: coverpoint curr_test{
			bins trunc[] = {TEST_WRITE_TRUNC, TEST_READ_TRUNC};
		}

		c_sleep: coverpoint curr_test{
			bins sleep [] = {TEST_POWER_DOWN, TEST_CLOCK_SUSPEND, TEST_SELF_REFRESH};
		}

		c_interleave: coverpoint curr_test{
			bins interleave[] = {TEST_BANK_INTERLEAVE_RW_AP, TEST_BANK_INTERLEAVE_RW_NP};
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
			bins sequential  = {1'b0};
			bins interleaved = {1'b1};
		}

		c_cas: coverpoint addr[6:4] iff (curr_cmd == CMD_LOAD_MODE){
			bins cas2  = {3'b010};
			bins cas3  = {3'b011};
		}

		c_opMode: coverpoint addr[8:7] iff (curr_cmd == CMD_LOAD_MODE){
			bins standard = {2'b00};
		}

		c_wbMode: coverpoint addr[9] iff (curr_cmd == CMD_LOAD_MODE){
			bins programed      = {1'b0};
			bins singleLocation = {1'b1};
		}

		cx_lmr_byte1_cas2_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b000} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte1_cas2_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b000} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_byte1_cas3_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b000} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte1_cas3_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b000} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_byte2_cas2_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b001} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte2_cas2_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b001} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_byte2_cas3_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b001} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte2_cas3_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b001} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_byte4_cas2_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b010} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte4_cas2_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b010} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_byte4_cas3_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b010} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte4_cas3_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b010} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_byte8_cas2_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b011} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte8_cas2_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b011} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_byte8_cas3_seq: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b011} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_byte8_cas3_inter: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b011} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_burstType)   intersect {1'b1};
		}

		cx_lmr_fullpage_cas2_programed: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b111} || 
								 !binsof(c_cas)         intersect {3'b010} ||
								 !binsof(c_wbMode)      intersect {1'b0}   ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

		cx_lmr_fullpage_cas3_programed: cross c_burstLength, c_burstType, c_cas, c_opMode, c_wbMode {
			ignore_bins others = !binsof(c_burstLength) intersect {3'b111} || 
								 !binsof(c_cas)         intersect {3'b011} ||
								 !binsof(c_wbMode)      intersect {1'b0}   ||
								 !binsof(c_burstType)   intersect {1'b0};
		}

	endgroup

	covergroup cg_data with function sample (bit [15:0] dq, bit [1:0] dqm);

		c_data_lower1: coverpoint dq iff (curr_cmd == CMD_WRITE || curr_cmd == CMD_READ) {
			bins lower_half1[8] = {[16'h0001:16'h3FFF]};
   		}

   		c_data_lower2: coverpoint dq iff (curr_cmd == CMD_WRITE || curr_cmd == CMD_READ) {
			bins lower_half2[8] = {[16'h4000:16'h7FFF]};
   		}

   		c_data_upper1: coverpoint dq iff (curr_cmd == CMD_WRITE || curr_cmd == CMD_READ) {
			bins upper_half1[8] = {[16'h8000:16'hBFFF]};
   		}

   		c_data_upper2: coverpoint dq iff (curr_cmd == CMD_WRITE || curr_cmd == CMD_READ) {
			bins upper_half2[8] = {[16'hC000:16'hFFFE]};
   		}


   		c_data_corner: coverpoint dq iff (curr_cmd == CMD_WRITE || curr_cmd == CMD_READ) {
			bins zeroes      = {16'h0000};
			bins ones 	     = {16'hFFFF};
			bins zeroes_ones = {16'h5555};
			bins ones_zeroes = {16'hAAAA};

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

	covergroup cg_addressing with function sample (bit [1:0] ba, bit [11:0] addr, test_e curr_test);

		c_bank_rows: coverpoint ba iff(curr_cmd == CMD_ACTIVE) {
			bins banks[4] = {2'b00, 2'b01, 2'b10, 2'b11};
		}

		c_bank_columns_write: coverpoint ba iff(curr_cmd == CMD_WRITE) {
			bins banks[4] = {2'b00, 2'b01, 2'b10, 2'b11};
		}

		c_bank_columns_read: coverpoint ba iff(curr_cmd == CMD_READ) {
			bins banks[4] = {2'b00, 2'b01, 2'b10, 2'b11};
		}

		c_rows_l1: coverpoint addr iff(curr_cmd == CMD_ACTIVE){
			bins lower[6] = {[12'h000:12'h3FF]};
		}

		c_rows_l2: coverpoint addr iff(curr_cmd == CMD_ACTIVE){
			bins lower[6] = {[12'h400:12'h7FF]};
		}

		c_rows_h1: coverpoint addr iff(curr_cmd == CMD_ACTIVE){
			bins upper[6] = {[12'h800:12'hBFF]};
		}

		c_rows_h2: coverpoint addr iff(curr_cmd == CMD_ACTIVE){
			bins upper[6] = {[12'hC00:12'hFFF]};
		}

	    c_columns_write_l: coverpoint addr[8:0] iff(curr_cmd == CMD_WRITE){
			bins allcolumns[6] = {[9'h000:9'h0FF]};
		}

		c_columns_write_h: coverpoint addr[8:0] iff(curr_cmd == CMD_WRITE){
			bins allcolumns[6] = {[9'h100:9'h1FF]};
		}

	    c_columns_read_l: coverpoint addr[8:0] iff(curr_cmd == CMD_READ){
			bins allcolumns[6] = {[9'h000:9'h0FF]};
		}

		c_columns_read_h: coverpoint addr[8:0] iff(curr_cmd == CMD_READ){
			bins allcolumns[6] = {[9'h100:9'h1FF]};
		}

		c_bank0_interleaving: coverpoint ba iff(curr_cmd == CMD_ACTIVE && 
											  (curr_test == TEST_BANK_INTERLEAVE_RW_AP || curr_test == TEST_BANK_INTERLEAVE_RW_NP)) {

			bins bank0_others[] = (2'b00 => 2'b01, 2'b10, 2'b11);
		}

		c_bank1_interleaving: coverpoint ba iff(curr_cmd == CMD_ACTIVE && 
											  (curr_test == TEST_BANK_INTERLEAVE_RW_AP || curr_test == TEST_BANK_INTERLEAVE_RW_NP)) {

			bins bank1_others[] = (2'b01 => 2'b00, 2'b10, 2'b11);
		}

		c_bank2_interleaving: coverpoint ba iff(curr_cmd == CMD_ACTIVE && 
											  (curr_test == TEST_BANK_INTERLEAVE_RW_AP || curr_test == TEST_BANK_INTERLEAVE_RW_NP)) {

			bins bank2_others[] = (2'b10 => 2'b00, 2'b01, 2'b11);
		}

		c_bank3_interleaving: coverpoint ba iff(curr_cmd == CMD_ACTIVE && 
											  (curr_test == TEST_BANK_INTERLEAVE_RW_AP || curr_test == TEST_BANK_INTERLEAVE_RW_NP)) {

			bins bank3_others[] = (2'b11 => 2'b00, 2'b01, 2'b10);
		}

		cx_active_row_l1_b0: cross c_bank_rows, c_rows_l1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b00};
        }

        cx_active_row_l2_b0: cross c_bank_rows, c_rows_l2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b00};
        }

        cx_active_row_h1_b0: cross c_bank_rows, c_rows_h1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b00};
        }

        cx_active_row_h2_b0: cross c_bank_rows, c_rows_h2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b00};
        }

        cx_active_row_l1_b1: cross c_bank_rows, c_rows_l1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b01};
        }

        cx_active_row_l2_b1: cross c_bank_rows, c_rows_l2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b01};
        }

        cx_active_row_h1_b1: cross c_bank_rows, c_rows_h1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b01};
        }

        cx_active_row_h2_b1: cross c_bank_rows, c_rows_h2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b01};
        }

        cx_active_row_l1_b2: cross c_bank_rows, c_rows_l1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b10};
        }

        cx_active_row_l2_b2: cross c_bank_rows, c_rows_l2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b10};
        }

        cx_active_row_h1_b2: cross c_bank_rows, c_rows_h1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b10};
        }

        cx_active_row_h2_b2: cross c_bank_rows, c_rows_h2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b10};
        }

        cx_active_row_l1_b3: cross c_bank_rows, c_rows_l1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b11};
        }

        cx_active_row_l2_b3: cross c_bank_rows, c_rows_l2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b11};
        }

        cx_active_row_h1_b3: cross c_bank_rows, c_rows_h1 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b11};
        }

        cx_active_row_h2_b3: cross c_bank_rows, c_rows_h2 {
            ignore_bins others = !binsof(c_bank_rows) intersect {2'b11};
        }



        cx_write_column_l_b0: cross c_bank_columns_write, c_columns_write_l {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b00};
        }

        cx_write_column_h_b0: cross c_bank_columns_write, c_columns_write_h {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b00};
        }

        cx_write_column_l_b1: cross c_bank_columns_write, c_columns_write_l {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b01};
        }

        cx_write_column_h_b1: cross c_bank_columns_write, c_columns_write_h {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b01};
        }

        cx_write_column_l_b2: cross c_bank_columns_write, c_columns_write_l {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b10};
        }

        cx_write_column_h_b2: cross c_bank_columns_write, c_columns_write_h {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b10};
        }

        cx_write_column_l_b3: cross c_bank_columns_write, c_columns_write_l {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b11};
        }

        cx_write_column_h_b3: cross c_bank_columns_write, c_columns_write_h {
            ignore_bins others = !binsof(c_bank_columns_write) intersect {2'b11};
        }



        cx_read_column_l_b0: cross c_bank_columns_read, c_columns_read_l {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b00};
        }

        cx_read_column_h_b0: cross c_bank_columns_read, c_columns_read_h {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b00};
        }

        cx_read_column_l_b1: cross c_bank_columns_read, c_columns_read_l {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b01};
        }

        cx_read_column_h_b1: cross c_bank_columns_read, c_columns_read_h {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b01};
        }

        cx_read_column_l_b2: cross c_bank_columns_read, c_columns_read_l {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b10};
        }

        cx_read_column_h_b2: cross c_bank_columns_read, c_columns_read_h {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b10};
        }

        cx_read_column_l_b3: cross c_bank_columns_read, c_columns_read_l {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b11};
        }

        cx_read_column_h_b3: cross c_bank_columns_read, c_columns_read_h {
            ignore_bins others = !binsof(c_bank_columns_read) intersect {2'b11};
        }
	endgroup


	  function new(string name, uvm_component parent);
	    super.new(name, parent);
	    cg_commands      = new();
	    cg_mode_register = new();
	    cg_data          = new();
	    cg_addressing    = new();
	  endfunction

	  function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(sdram_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "Nie udalo sie pobrac sdram_cfg z uvm_config_db")
        end

        uvm_config_db#(sdram_coverage_ddor)::set(null, "*", "cov", this);
    endfunction

	  function void write(sdram_mon_item t);
	    curr_mon_item = t;
	    curr_cmd      = t.curr_cmd;

	    cg_commands.sample(curr_cmd, t.addr, t.cke, cfg.curr_test);
    	cg_mode_register.sample(t.addr);
    	cg_data.sample(t.dq, t.dqm);
    	cg_addressing.sample(t.ba, t.addr, cfg.curr_test);
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
