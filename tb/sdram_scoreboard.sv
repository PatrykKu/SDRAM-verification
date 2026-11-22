class sdram_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(sdram_scoreboard)
	uvm_analysis_imp #(sdram_mon_item, sdram_scoreboard) ap_imp;

	bit [15:0] mem_model [bit[13:0]];

	typedef enum {
	IDLE,
	GET_WRITE,
	GET_READ,
	CAS_WAITING
	} state_e;

	state_e state = IDLE;

    bit [13:0] curr_addr;
    bit [11:0] active_row [4];
    bit [8:0]  start_column;
    bit [1:0]  curr_bank;
    int burst_elem;
    int cas_count;
    int sb_cas_latency   = 2;
    int sb_burst_length  = 2;
    bit sb_wb_mode       = 1'b0;
    string sb_burst_type = "";

    bit [1:0]  item_mask  [int];

	function new(string name = "sdram_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(sdram_mon_item mon_item);
       	bit [13:0] item_addr;
       	bit [8:0]  item_column;
       	bit [11:0] item_row;

    	item_addr   = {mon_item.ba, mon_item.addr[8:0]};
    	item_column = mon_item.addr[8:0];
    	item_row    = mon_item.addr[11:0];

    	case (state)
    		IDLE: begin
    			if (mon_item.curr_cmd == CMD_LOAD_MODE) begin
				    sb_burst_length = sdram_mode_register::code_to_burst_length(mon_item.addr[2:0]);
				    sb_cas_latency  = sdram_mode_register::cas_to_latency(mon_item.addr[6:4]);
				    sb_wb_mode      = mon_item.addr[9];
				    sb_burst_type   = (mon_item.addr[3] == 1'b0) ? "Sequential" : "Interleaved";

				    `uvm_info("SCOREBOARD", $sformatf("LMR zdekodowany z magistrali: CAS=%0d BurstLength=%0d WB=%0d BurstType=%0s (addr=%h)", 
				    	      sb_cas_latency, sb_burst_length, sb_wb_mode, sb_burst_type, mon_item.addr), UVM_MEDIUM)
				end
				if (mon_item.curr_cmd == CMD_ACTIVE) begin
					active_row[mon_item.ba] = item_row;
				    `uvm_info("SCOREBOARD", $sformatf("Aktywowany wiersz: @bank%h @curr_row=%h",mon_item.ba, item_row), UVM_MEDIUM)
				end
    			if (mon_item.curr_cmd == CMD_WRITE) begin
    				curr_addr = item_addr;
    				mem_model[curr_addr] = mon_item.dq;
    				start_column = item_column;
    				curr_bank = mon_item.ba;

    				item_mask[0] = mon_item.dqm;
    				burst_elem = 1;
    				state = (sb_burst_length == 1 || sb_wb_mode == 1'b1) ? IDLE : GET_WRITE;
    				`uvm_info("SCOREBOARD", $sformatf("WRITE start @byte0 @bank%h @curr_column=%h data=%h byte_mask=%b", 
    												   mon_item.ba, item_column, mon_item.dq, mon_item.dqm), UVM_MEDIUM)
    			end
    			else if (mon_item.curr_cmd == CMD_READ) begin
    				curr_addr = item_addr;
    				start_column = item_column;
    				curr_bank = mon_item.ba;
    				cas_count = sb_cas_latency - 1;
    				burst_elem = 0;
    				state = CAS_WAITING;
    				`uvm_info("SCOREBOARD", $sformatf("READ start @bank%h @curr_column=%h", mon_item.ba, item_column), UVM_MEDIUM)
    			end
    		end

    		GET_WRITE: begin
    			if (mon_item.curr_cmd == CMD_BURST_TERMINATE || mon_item.curr_cmd == CMD_PRECHARGE) begin
                    state = IDLE;
                end 
                else begin
	    			mem_model[curr_addr + burst_elem] = mon_item.dq;
	    			item_mask[burst_elem] = mon_item.dqm;
	    			`uvm_info("SCOREBOARD", $sformatf("WRITE byte @byte%0d @bank%h @start_column=%h @virtual_column=%03h data=%h byte_mask=%b", 
	    				burst_elem, curr_bank, start_column, (start_column+burst_elem), mon_item.dq, mon_item.dqm), UVM_MEDIUM)
	    			 burst_elem++;
	    			if (sb_burst_length != 0 && burst_elem >= sb_burst_length) state = IDLE;
	    		end
    		end

    		GET_READ: begin
    			if (mon_item.curr_cmd == CMD_BURST_TERMINATE || mon_item.curr_cmd == CMD_PRECHARGE) begin
                   	if (sb_cas_latency == 3) begin
                   	    `uvm_info("SCOREBOARD", $sformatf("READ byte @byte%0d @bank%h @start_column=%h @virtual_column=%03h data=%h", 
		    				burst_elem, curr_bank, start_column, (start_column+burst_elem), mon_item.dq), UVM_MEDIUM)
		    			check_read(curr_addr + burst_elem, mon_item.dq, item_mask[burst_elem]);
		    			burst_elem++;
                   		state = IDLE;
                	end 

                	else begin
                		state = IDLE;
                	end
                end

                else begin
		    		`uvm_info("SCOREBOARD", $sformatf("READ byte @byte%0d @bank%h @start_column=%h @virtual_column=%03h data=%h", 
		    			burst_elem, curr_bank, start_column, (start_column+burst_elem), mon_item.dq), UVM_MEDIUM)
		    		check_read(curr_addr + burst_elem, mon_item.dq, item_mask[burst_elem]);
		    		burst_elem++;

	                if (sb_burst_length != 0 && burst_elem >= sb_burst_length) begin
		    			state = IDLE;
		    		end
		    	end
    		end

    		CAS_WAITING: begin
    			if (cas_count > 0) cas_count--;
    			else begin
    				`uvm_info("SCOREBOARD", $sformatf("READ byte @byte%0d @bank%h @start_column=%h @virtual_column=%03h data=%h", 
		    			burst_elem, curr_bank, start_column, (start_column+burst_elem), mon_item.dq), UVM_MEDIUM)
    				check_read(curr_addr + burst_elem, mon_item.dq, item_mask[burst_elem]);
		    		burst_elem++;
    				state = ((sb_burst_length != 0 && burst_elem >= sb_burst_length) || sb_wb_mode == 1'b1) ? IDLE : GET_READ;
    			end
    		end
    	endcase
    endfunction

    function void check_read (bit [13:0] item_addr, bit [15:0] data, bit [1:0] mask);
    	bit [15:0] expected_data;
    	expected_data = mem_model[item_addr];

    	if (data === expected_data)
    		`uvm_info("SCOREBOARD", $sformatf("TE SAME DANE @curr_addr=%h exp=%h data=%h", item_addr, expected_data, data), UVM_MEDIUM)

    	else if (mask == 2'b00 && (data[7:0] === 8'h0 || data[7:0] === expected_data[7:0]) &&
                 (data[15:8] === 8'h0 || data[15:8] === expected_data[15:8]))
            `uvm_info("SCOREBOARD", $sformatf("HIGH-Z (MASKOWANIE) @curr_addr=%h exp=%h data=%h", item_addr, expected_data, data), UVM_MEDIUM)

        else if ((data == {8'h00, expected_data[7:0]} && mask == 2'b10)  ||
        		 (data == {expected_data[15:8], 8'h00} && mask == 2'b01) ||
        		 (data == 16'h0000 && mask == 2'b11))
        	`uvm_info("SCOREBOARD", $sformatf("MASKA DANYCH @curr_addr=%h exp=%h data=%h data_mask=%h", item_addr, expected_data, data, mask), UVM_MEDIUM)

        else
            `uvm_warning("SCOREBOARD", $sformatf("MISMATCH @curr_addr=%h exp=%h got=%h", item_addr, expected_data, data))

    endfunction
endclass