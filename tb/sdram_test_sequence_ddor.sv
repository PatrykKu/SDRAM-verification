class sdram_test_sequence extends uvm_sequence #(sdram_transaction);
    `uvm_object_utils(sdram_test_sequence)

    sdram_cfg cfg;
    sdram_coverage_ddor cov;
    string    s;
    rand int  next_op_trunc;
    bit       override_addr_trans;

    int unsigned  num_iter = 2000;
    function new(string name = "sdram_test_sequence");
        super.new(name);
    endfunction

    function void update_data_target();
        real cov_data[5];
        real min_cov;
        int  min_id;

        cov_data[0] = cov.cg_data.c_data_lower1.get_coverage();
        cov_data[1] = cov.cg_data.c_data_lower2.get_coverage();
        cov_data[2] = cov.cg_data.c_data_upper1.get_coverage();
        cov_data[3] = cov.cg_data.c_data_upper2.get_coverage();
        cov_data[4] = cov.cg_data.c_data_corner.get_coverage();

        if (cov_data[0] == 100.0 && cov_data[1] == 100.0 && cov_data[2] == 100.0 
         && cov_data[3] == 100.0 && cov_data[4] == 100.0) begin
            cfg.data_scope = 5;
        end

        else begin
            min_cov = cov_data[0];
            min_id  = 0;

            for (int i = 1; i <= 4; i++) begin
                if (cov_data[i] < min_cov) begin
                    min_cov = cov_data[i];
                    min_id  = i;
                end
            end

            cfg.data_scope = min_id;
        end
    endfunction

    function void update_addressing_target();
        real bank_interleave[4];
        real bank_cov[4];
        real row_l1_cov[4], row_l2_cov[4], row_h1_cov[4], row_h2_cov[4];
        real row_l_cov[4], row_h_cov[4];
        real col_l_cov[4], col_h_cov[4];

        real min_inter_cov;
        int  worst_inter;

        real min_bank_cov;
        int  worst_bank;

        bank_interleave[0] = cov.cg_addressing.c_bank0_interleaving.get_coverage();
        bank_interleave[1] = cov.cg_addressing.c_bank1_interleaving.get_coverage();
        bank_interleave[2] = cov.cg_addressing.c_bank2_interleaving.get_coverage();
        bank_interleave[3] = cov.cg_addressing.c_bank3_interleaving.get_coverage();

        worst_bank     = 0;
        min_inter_cov  = bank_interleave[0];

        for (int i = 1; i <= 3; i++) begin
            if (bank_interleave[i] < min_inter_cov) begin
                min_inter_cov = bank_interleave[i];
                worst_bank = i;
            end
        end

        if (min_inter_cov == 100.0) begin
            override_addr_trans = 1;
        end

        else begin
            override_addr_trans = 0;
            cfg.curr_cdv = CHECK_INTERLEAVE;
        end
        
        row_l1_cov[0] = cov.cg_addressing.cx_active_row_l1_b0.get_coverage();
        row_l2_cov[0] = cov.cg_addressing.cx_active_row_l2_b0.get_coverage();
        row_h1_cov[0] = cov.cg_addressing.cx_active_row_h1_b0.get_coverage();
        row_h2_cov[0] = cov.cg_addressing.cx_active_row_h2_b0.get_coverage();
        row_l_cov[0]  = (row_l1_cov[0] + row_l2_cov[0]) / 2.0;
        row_h_cov[0]  = (row_h1_cov[0] + row_h2_cov[0]) / 2.0;
        col_l_cov[0]  = (cov.cg_addressing.cx_write_column_l_b0.get_coverage() + cov.cg_addressing.cx_read_column_l_b0.get_coverage()) / 2.0;
        col_h_cov[0]  = (cov.cg_addressing.cx_write_column_h_b0.get_coverage() + cov.cg_addressing.cx_read_column_h_b0.get_coverage()) / 2.0;
        bank_cov[0]   = (row_l_cov[0] + row_h_cov[0] + col_l_cov[0] + col_h_cov[0]) / 4.0;

        row_l1_cov[1] = cov.cg_addressing.cx_active_row_l1_b1.get_coverage();
        row_l2_cov[1] = cov.cg_addressing.cx_active_row_l2_b1.get_coverage();
        row_h1_cov[1] = cov.cg_addressing.cx_active_row_h1_b1.get_coverage();
        row_h2_cov[1] = cov.cg_addressing.cx_active_row_h2_b1.get_coverage();
        row_l_cov[1]  = (row_l1_cov[1] + row_l2_cov[1]) / 2.0;
        row_h_cov[1]  = (row_h1_cov[1] + row_h2_cov[1]) / 2.0;
        col_l_cov[1] = (cov.cg_addressing.cx_write_column_l_b1.get_coverage() + cov.cg_addressing.cx_read_column_l_b1.get_coverage()) / 2.0;
        col_h_cov[1] = (cov.cg_addressing.cx_write_column_h_b1.get_coverage() + cov.cg_addressing.cx_read_column_h_b1.get_coverage()) / 2.0;
        bank_cov[1]  = (row_l_cov[1] + row_h_cov[1] + col_l_cov[1] + col_h_cov[1]) / 4.0;

        row_l1_cov[2] = cov.cg_addressing.cx_active_row_l1_b2.get_coverage();
        row_l2_cov[2] = cov.cg_addressing.cx_active_row_l2_b2.get_coverage();
        row_h1_cov[2] = cov.cg_addressing.cx_active_row_h1_b2.get_coverage();
        row_h2_cov[2] = cov.cg_addressing.cx_active_row_h2_b2.get_coverage();
        row_l_cov[2]  = (row_l1_cov[2] + row_l2_cov[2]) / 2.0;
        row_h_cov[2]  = (row_h1_cov[2] + row_h2_cov[2]) / 2.0;
        col_l_cov[2] = (cov.cg_addressing.cx_write_column_l_b2.get_coverage() + cov.cg_addressing.cx_read_column_l_b2.get_coverage()) / 2.0;
        col_h_cov[2] = (cov.cg_addressing.cx_write_column_h_b2.get_coverage() + cov.cg_addressing.cx_read_column_h_b2.get_coverage()) / 2.0;
        bank_cov[2]  = (row_l_cov[2] + row_h_cov[2] + col_l_cov[2] + col_h_cov[2]) / 4.0;

        row_l1_cov[3] = cov.cg_addressing.cx_active_row_l1_b3.get_coverage();
        row_l2_cov[3] = cov.cg_addressing.cx_active_row_l2_b3.get_coverage();
        row_h1_cov[3] = cov.cg_addressing.cx_active_row_h1_b3.get_coverage();
        row_h2_cov[3] = cov.cg_addressing.cx_active_row_h2_b3.get_coverage();
        row_l_cov[3]  = (row_l1_cov[3] + row_l2_cov[3]) / 2.0;
        row_h_cov[3]  = (row_h1_cov[3] + row_h2_cov[3]) / 2.0;
        col_l_cov[3] = (cov.cg_addressing.cx_write_column_l_b3.get_coverage() + cov.cg_addressing.cx_read_column_l_b3.get_coverage()) / 2.0;
        col_h_cov[3] = (cov.cg_addressing.cx_write_column_h_b3.get_coverage() + cov.cg_addressing.cx_read_column_h_b3.get_coverage()) / 2.0;
        bank_cov[3]  = (row_l_cov[3] + row_h_cov[3] + col_l_cov[3] + col_h_cov[3]) / 4.0;

        min_bank_cov = bank_cov[0];

        if (override_addr_trans) begin
            cfg.curr_cdv = CHECK_NORMAL_TRANS;
            for (int i = 1; i < 4; i++) begin
                if (bank_cov[i] < min_bank_cov) begin
                    min_bank_cov = bank_cov[i];
                    worst_bank = i;
                end
            end

            if (min_bank_cov == 100.0) begin
                cfg.curr_cdv  = CHECK_RANDOM_TRANS;
                cfg.row_scope = 4;
                cfg.col_scope = 2;
                worst_bank = 4;
            end
        end

        if (min_bank_cov == 100.0) begin
            cfg.row_scope = 4;
            cfg.col_scope = 2;
        end

        else begin
            if (row_l_cov[worst_bank] < row_h_cov[worst_bank]) begin
                if (row_l1_cov[worst_bank] < row_l2_cov[worst_bank]) 
                    cfg.row_scope = 0;
                else 
                    cfg.row_scope = 1;
            end
            else begin
                if (row_h1_cov[worst_bank] < row_h2_cov[worst_bank]) 
                    cfg.row_scope = 2;
                else 
                    cfg.row_scope = 3;
            end

            if (col_l_cov[worst_bank] < col_h_cov[worst_bank]) 
                cfg.col_scope = 0;
            else 
                cfg.col_scope = 1;
        end

        cfg.selectedBank = worst_bank;
    endfunction

    function void update_lmr_target();
        real cov_cas2_seq[5]; //0 - 1byte 4 - full page 
        real cov_cas2_inter[4];
        real cov_cas3_seq[5];
        real cov_cas3_inter[4];

        real cov_lmr[5]; //0 - 1byte 4 - full page 

        real min_lmr_cov;
        int  worst_lmr;

        cov_cas2_seq[0]   = cov.cg_mode_register.cx_lmr_byte1_cas2_seq.get_coverage();
        cov_cas2_inter[0] = cov.cg_mode_register.cx_lmr_byte1_cas2_inter.get_coverage();
        cov_cas3_seq[0]   = cov.cg_mode_register.cx_lmr_byte1_cas3_seq.get_coverage();
        cov_cas3_inter[0] = cov.cg_mode_register.cx_lmr_byte1_cas3_inter.get_coverage();
        cov_lmr[0] = (cov_cas2_seq[0] + cov_cas2_inter[0] + cov_cas3_seq[0] + cov_cas3_inter[0]) /4.0;

        cov_cas2_seq[1]   = cov.cg_mode_register.cx_lmr_byte2_cas2_seq.get_coverage();
        cov_cas2_inter[1] = cov.cg_mode_register.cx_lmr_byte2_cas2_inter.get_coverage();
        cov_cas3_seq[1]   = cov.cg_mode_register.cx_lmr_byte2_cas3_seq.get_coverage();
        cov_cas3_inter[1] = cov.cg_mode_register.cx_lmr_byte2_cas3_inter.get_coverage();
        cov_lmr[1] = (cov_cas2_seq[1] + cov_cas2_inter[1] + cov_cas3_seq[1] + cov_cas3_inter[1]) /4.0;

        cov_cas2_seq[2]   = cov.cg_mode_register.cx_lmr_byte4_cas2_seq.get_coverage();
        cov_cas2_inter[2] = cov.cg_mode_register.cx_lmr_byte4_cas2_inter.get_coverage();
        cov_cas3_seq[2]   = cov.cg_mode_register.cx_lmr_byte4_cas3_seq.get_coverage();
        cov_cas3_inter[2] = cov.cg_mode_register.cx_lmr_byte4_cas3_inter.get_coverage();
        cov_lmr[2] = (cov_cas2_seq[2] + cov_cas2_inter[2] + cov_cas3_seq[2] + cov_cas3_inter[2]) /4.0;

        cov_cas2_seq[3]   = cov.cg_mode_register.cx_lmr_byte8_cas2_seq.get_coverage();
        cov_cas2_inter[3] = cov.cg_mode_register.cx_lmr_byte8_cas2_inter.get_coverage();
        cov_cas3_seq[3]   = cov.cg_mode_register.cx_lmr_byte8_cas3_seq.get_coverage();
        cov_cas3_inter[3] = cov.cg_mode_register.cx_lmr_byte8_cas3_inter.get_coverage();
        cov_lmr[3] = (cov_cas2_seq[3] + cov_cas2_inter[3] + cov_cas3_seq[3] + cov_cas3_inter[3]) /4.0;

        cov_cas2_seq[4]   = cov.cg_mode_register.cx_lmr_fullpage_cas2_programed.get_coverage();
        cov_cas3_seq[4]   = cov.cg_mode_register.cx_lmr_fullpage_cas3_programed.get_coverage();
        cov_lmr[4] = (cov_cas2_seq[4] + cov_cas3_seq[4]) /2.0;

        min_lmr_cov = cov_lmr[0];

        for (int i = 1; i <= 3; i++) begin
                if (cov_lmr[i] < min_lmr_cov) begin
                    min_lmr_cov = cov_lmr[i];
                    worst_lmr = i;
            end
        end

        if (min_lmr_cov == 100.0) begin
            cfg.CAS_scope  = 2;
            cfg.WB_scope   = 2;
            cfg.BT_scope   = 2;
            cfg.byte_scope = 4;
            return;
        end

        if ((cov_lmr[4] < min_lmr_cov) && override_addr_trans == 1) begin
            cfg.curr_cdv = CHECK_FULL_PAGE;
            cfg.WB_scope = 0;
            cfg.BT_scope = 0;
            if (cov_cas2_seq[4] < cov_cas3_seq[4]) begin
                cfg.CAS_scope = 0;
            end
            else begin
                cfg.CAS_scope = 1;
            end
        end 

        else begin
            if (override_addr_trans == 1) begin
                cfg.curr_cdv = CHECK_NORMAL_TRANS;
            end
            cfg.byte_scope = worst_lmr;
            cfg.WB_scope   = 2;
            if ((cov_cas2_seq[worst_lmr] + cov_cas2_inter[worst_lmr]) < (cov_cas3_seq[worst_lmr] + cov_cas3_inter[worst_lmr])) begin
                cfg.CAS_scope = 0;
                if (cov_cas2_seq[worst_lmr] < cov_cas2_inter[worst_lmr]) begin
                    cfg.BT_scope = 0;
                end
                else begin
                    cfg.BT_scope = 1;
                end
            end
            else begin
                cfg.CAS_scope = 1;
                if (cov_cas3_seq[worst_lmr] < cov_cas3_inter[worst_lmr]) begin
                    cfg.BT_scope = 0;
                end
                else begin
                    cfg.BT_scope = 1;
                end
            end
        end
    endfunction

    function void update_cmd_target();
        real cmd_cov[3];
        real min_cmd_cov;
        int  worst_cmd;

        cmd_cov[0] = cov.cg_commands.c_highz.get_coverage();
        cmd_cov[1] = cov.cg_commands.c_trunc.get_coverage();
        cmd_cov[2] = cov.cg_commands.c_sleep.get_coverage();

        min_cmd_cov = cmd_cov[0];

        for (int i = 1; i <= 2; i++) begin
                if (cmd_cov[i] < min_cmd_cov) begin
                    min_cmd_cov = cmd_cov[i];
                    worst_cmd = i;
            end
        end

        if (min_cmd_cov == 100.0) begin
            return;
        end

        case (worst_cmd)
            0: begin
                cfg.curr_cdv = CHECK_HZ;
            end
            1: begin
                cfg.curr_cdv = CHECK_TRUNC;
            end
            2: begin
                cfg.curr_cdv = CHECK_SLEEP;
            end
        endcase
    endfunction

    task body();
        int file_handle;
        int current_iter;
        sdram_transaction tx;
        real t_start, t_end, t_total;
        t_total = 0.0;

        if (!uvm_config_db#(sdram_cfg)::get(m_sequencer, "", "cfg", cfg))
            `uvm_fatal("NO_CFG", "Sekwencja: brak sdram_cfg")

        if (!uvm_config_db#(sdram_coverage_ddor)::get(m_sequencer, "", "cov", cov))
            `uvm_fatal("NO_COV", "Sekwencja: brak sdram_cov")

        file_handle = $fopen("coverage_report.txt", "w");
        if (file_handle) begin
            $fdisplay(file_handle, "Iteracja | CG_Commands| CG_Mode_Reg | CG_Addressing | CG_Data ");
            $fdisplay(file_handle, "--------------------------------------------------------------");
        end else begin
            `uvm_error("FILE_IO", "Nie udalo sie otworzyc pliku coverage_report.txt")
        end

        //Command Inhibit
        tx = sdram_transaction::type_id::create("tx_command_inhibit");
        start_item(tx);
        tx.op = sdram_transaction::OP_CI;
        finish_item(tx);

        // Init
        tx = sdram_transaction::type_id::create("tx_init");
        start_item(tx);
        tx.op = sdram_transaction::OP_INIT;
        finish_item(tx);

        for (int unsigned n = 0; n < num_iter; n++) begin
            t_start = get_cpu_time();
            update_data_target(); 
            update_addressing_target(); 
            update_lmr_target();
            update_cmd_target();
            t_end = get_cpu_time();
            t_total += (t_end - t_start);
            
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

                        //next_op_trunc = $urandom_range(0, 1);
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
                            // tx = sdram_transaction::type_id::create("tx_nop");
                            // start_item(tx);
                            //     tx.op           = sdram_transaction::OP_CI;
                            // finish_item(tx);

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

            current_iter = n + 1;
            if (current_iter inside {1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 150, 200, 250, 300, 350, 400, 500, 1000, 2000}) begin
                if (file_handle) begin
                    $fdisplay(file_handle, "%8d | %11.2f | %11.2f | %13.2f | %7.2f",
                        current_iter,
                        cov.cg_commands.get_coverage(),
                        cov.cg_mode_register.get_coverage(),
                        cov.cg_addressing.get_coverage(),
                        cov.cg_data.get_coverage()
                    );
                end
            end
        end

        if (file_handle) begin
            $fclose(file_handle);
        end
        `uvm_info("CPU_TIME", $sformatf("Calkowity czas funkcji update_*: %f sekund", t_total), UVM_NONE)
    endtask
endclass