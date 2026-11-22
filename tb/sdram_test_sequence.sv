class sdram_test_sequence extends uvm_sequence #(sdram_transaction);
    `uvm_object_utils(sdram_test_sequence)

    sdram_cfg cfg;
    string    s;
    rand int  next_op_trunc;

    int unsigned  num_iter = 25;

    function new(string name = "sdram_test_sequence");
        super.new(name);
    endfunction

    task body();
        sdram_transaction tx;

        if (!uvm_config_db#(sdram_cfg)::get(m_sequencer, "", "cfg", cfg))
            `uvm_fatal("NO_CFG", "Sekwencja: brak sdram_cfg")

        tx = sdram_transaction::type_id::create("tx_command_inhibit");
        start_item(tx);
        tx.op = sdram_transaction::OP_CI;
        finish_item(tx);

        tx = sdram_transaction::type_id::create("tx_init");
        start_item(tx);
        tx.op = sdram_transaction::OP_INIT;
        finish_item(tx);

        for (int unsigned n = 0; n < num_iter; n++) begin

        if (!cfg.randomize())
            `uvm_fatal("RANDFAIL", "nie udalo sie wylosowac sdram_cfg")

            tx = sdram_transaction::type_id::create("tx_prep");
            start_item(tx);
                tx.op               = sdram_transaction::OP_PREP;
                tx.bank             = cfg.bank;
                tx.row              = cfg.row;
                tx.burstLength      = cfg.burstLength;
                tx.burst_type       = cfg.burstType;
                tx.cas              = cfg.casBits;
                tx.write_burst_mode = cfg.writeBurstMode;
            finish_item(tx);

            case (cfg.curr_test)

                TEST_BURST_RW_AP: begin
                    `uvm_info("TEST_BURST_RW_AP", $sformatf("TEST_BURST_RW_AP"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_write");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_AP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);  

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                        tx.bank = cfg.bank;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_active_ap");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank;
                        tx.row              = cfg.row;
                    finish_item(tx);  
                    
                    tx = sdram_transaction::type_id::create("tx_read");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_AP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_BURST_RW_NP: begin
                    `uvm_info("TEST_BURST_RW_NP", $sformatf("TEST_BURST_RW_NP"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_write");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);     
                    
                    tx = sdram_transaction::type_id::create("tx_read");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_NP_BANK;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_BURST_RW_AP_HZ: begin
                    `uvm_info("TEST_BURST_RW_AP_HIGHZ", $sformatf("TEST_BURST_RW_AP_HIGHZ"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_write");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_AP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);  

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                        tx.bank = cfg.bank;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_active_ap");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank;
                        tx.row              = cfg.row;
                    finish_item(tx);  
                    
                    tx = sdram_transaction::type_id::create("tx_read_hz");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_AP_HZ;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.byte_mask    = new[cfg.burstSize];
                        foreach(tx.byte_mask[i]) tx.byte_mask[i] = $urandom_range(0, 2);
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_BURST_RW_NP_HZ: begin
                    `uvm_info("TEST_BURST_RW_NP_HIGHZ", $sformatf("TEST_BURST_RW_NP_HIGHZ"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_write");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);     
                    
                    tx = sdram_transaction::type_id::create("tx_read_hz");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_NP_HZ;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.byte_mask    = new[cfg.burstSize];
                        foreach(tx.byte_mask[i]) tx.byte_mask[i] = $urandom_range(0, 3);
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_NP_BANK;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_FULL_PAGE_RW_NP: begin
                    `uvm_info("TEST_FULL_PAGE_RW_NP", $sformatf("TEST_FULL_PAGE_RW_NP"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_write");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);     
                    
                    tx = sdram_transaction::type_id::create("tx_read");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_NP_BANK;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_BANK_INTERLEAVE_RW_NP: begin
                    `uvm_info("TEST_BANK_INTERLEAVE_RW_NP", $sformatf("TEST_BANK_INTERLEAVE_RW_NP"), UVM_LOW)

                    tx = sdram_transaction::type_id::create("tx_active2");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank2;
                        tx.row              = cfg.row;
                    finish_item(tx);  

                    tx = sdram_transaction::type_id::create("tx_write1");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);

                    tx = sdram_transaction::type_id::create("tx_write2");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_NP;
                        tx.bank         = cfg.bank2;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = new[cfg.burstSize];
                        tx.byte_mask    = cfg.byteMask;
                        foreach(tx.data[i]) tx.data[i] = ~cfg.data[i];
                    finish_item(tx);      
                    
                    tx = sdram_transaction::type_id::create("tx_read1");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_read2");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_NP;
                        tx.bank         = cfg.bank2;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_NP_ALL;
                    finish_item(tx);
                end

                TEST_BANK_INTERLEAVE_RW_AP: begin
                    `uvm_info("TEST_BANK_INTERLEAVE_RW_AP", $sformatf("TEST_BANK_INTERLEAVE_RW_AP"), UVM_LOW)

                    tx = sdram_transaction::type_id::create("tx_active2");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank2;
                        tx.row              = cfg.row;
                    finish_item(tx);  

                    tx = sdram_transaction::type_id::create("tx_write1");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_AP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);

                    tx = sdram_transaction::type_id::create("tx_write2");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_AP;
                        tx.bank         = cfg.bank2;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = new[cfg.burstSize];
                        tx.byte_mask    = cfg.byteMask;
                        foreach(tx.data[i]) tx.data[i] = ~cfg.data[i];
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                    finish_item(tx);  

                    tx = sdram_transaction::type_id::create("tx_active1");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank;
                        tx.row              = cfg.row;
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_active2");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank2;
                        tx.row              = cfg.row;
                    finish_item(tx); 
                    
                    tx = sdram_transaction::type_id::create("tx_read1");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_AP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_read2");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_AP;
                        tx.bank         = cfg.bank2;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                    finish_item(tx);
                end

                TEST_CLOCK_SUSPEND: begin
                    `uvm_info("TEST_CLOCK_SUSPEND", $sformatf("TEST_CLOCK_SUSPEND"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_write");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_SUSPEND;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx);     
                    
                    tx = sdram_transaction::type_id::create("tx_read");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_SUSPEND;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                    finish_item(tx);    

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_NP_BANK;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_WRITE_TRUNC: begin
                    `uvm_info("TEST_WRITE_TRUNC", $sformatf("TEST_WRITE_TRUNC"), UVM_LOW)

                    tx = sdram_transaction::type_id::create("tx_active2");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank2;
                        tx.row              = cfg.row;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_write2");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_NP;
                        tx.bank         = cfg.bank2;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_write_trunc");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_TRUNC;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                        tx.stop_point   = cfg.stop_point;
                    finish_item(tx);  

                    next_op_trunc = $urandom_range(0, 1);

                    if (next_op_trunc == 0) begin
                        tx = sdram_transaction::type_id::create("tx_read");
                        start_item(tx);
                            tx.op           = sdram_transaction::OP_READ_AP;
                            tx.bank         = cfg.bank2;
                            tx.start_column = cfg.startColumn;
                            tx.burstLength  = cfg.burstLength;
                            tx.burstSize    = cfg.burstSize;
                        finish_item(tx);  
                    end

                    else begin
                        tx = sdram_transaction::type_id::create("tx_write");
                        start_item(tx);
                            tx.op           = sdram_transaction::OP_WRITE_AP;
                            tx.bank         = cfg.bank2;
                            tx.start_column = cfg.startColumn;
                            tx.burstLength  = cfg.burstLength;
                            tx.burstSize    = cfg.burstSize;
                            tx.data         = cfg.data;
                            tx.byte_mask    = cfg.byteMask;
                        finish_item(tx); 
                    end

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_READ_TRUNC: begin
                    `uvm_info("TEST_READ_TRUNC", $sformatf("TEST_READ_TRUNC"), UVM_LOW)

                    tx = sdram_transaction::type_id::create("tx_active2");
                    start_item(tx);
                        tx.op               = sdram_transaction::OP_ACTIVE;
                        tx.bank             = cfg.bank2;
                        tx.row              = cfg.row;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_write");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_WRITE_NP;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                    finish_item(tx); 

                    tx = sdram_transaction::type_id::create("tx_read_trunc");
                    start_item(tx);
                        tx.op           = sdram_transaction::OP_READ_TRUNC;
                        tx.bank         = cfg.bank;
                        tx.start_column = cfg.startColumn;
                        tx.burstLength  = cfg.burstLength;
                        tx.burstSize    = cfg.burstSize;
                        tx.data         = cfg.data;
                        tx.byte_mask    = cfg.byteMask;
                        tx.stop_point   = cfg.stop_point;
                    finish_item(tx);  

                    next_op_trunc = 1;

                    if (next_op_trunc == 0) begin
                        tx = sdram_transaction::type_id::create("tx_read");
                        start_item(tx);
                            tx.op           = sdram_transaction::OP_READ_AP;
                            tx.bank         = cfg.bank2;
                            tx.start_column = cfg.startColumn;
                            tx.burstLength  = cfg.burstLength;
                            tx.burstSize    = cfg.burstSize;
                        finish_item(tx);  
                    end

                    else begin
                        tx = sdram_transaction::type_id::create("tx_write");
                        start_item(tx);
                            tx.op           = sdram_transaction::OP_WRITE_AP;
                            tx.bank         = cfg.bank2;
                            tx.start_column = cfg.startColumn;
                            tx.burstLength  = cfg.burstLength;
                            tx.burstSize    = cfg.burstSize;
                            tx.data         = cfg.data;
                            tx.byte_mask    = cfg.byteMask;
                        finish_item(tx); 
                    end

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_AP;
                        tx.bank = cfg.bank;
                    finish_item(tx);
                end

                TEST_POWER_DOWN: begin
                    `uvm_info("TEST_POWER_DOWN", $sformatf("TEST_POWER_DOWN"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_enter_power_down");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_ENTER_PD;
                    finish_item(tx);

                    tx = sdram_transaction::type_id::create("tx_exit_power_down");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_EXIT_PD;
                    finish_item(tx);

                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_NP_ALL;
                    finish_item(tx);
                end

                TEST_SELF_REFRESH: begin
                    tx = sdram_transaction::type_id::create("tx_deact");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_DEAT_NP_ALL;
                    finish_item(tx);
                    
                    `uvm_info("TEST_SELF_REFRESH", $sformatf("TEST_SELF_REFRESH"), UVM_LOW)
                    tx = sdram_transaction::type_id::create("tx_self_refresh");
                    start_item(tx);
                        tx.op   = sdram_transaction::OP_SELF_REFRESH;
                    finish_item(tx);
                end

            endcase

            s = "";
            foreach (tx.read_data[i])
                s = {s, $sformatf("%h ", tx.read_data[i])};
            `uvm_info("READBACK", $sformatf("Read back: %s", s), UVM_LOW)
        end
    endtask
endclass