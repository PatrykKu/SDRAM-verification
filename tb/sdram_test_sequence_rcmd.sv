class sdram_test_sequence extends uvm_sequence #(sdram_transaction);
    `uvm_object_utils(sdram_test_sequence)

    sdram_cfg cfg;
    string    s;
    rand int  next_op_trunc;

    int unsigned  num_iter = 10;

    function new(string name = "sdram_test_sequence");
        super.new(name);
    endfunction

    task body();
        sdram_transaction tx;

        if (!uvm_config_db#(sdram_cfg)::get(m_sequencer, "", "cfg", cfg))
            `uvm_fatal("NO_CFG", "Sekwencja: brak sdram_cfg")

        for (int unsigned n = 0; n < num_iter; n++) begin

        if (!cfg.randomize())
            `uvm_fatal("RANDFAIL", "nie udalo sie wylosowac sdram_cfg")

            tx = sdram_transaction::type_id::create("tx_prep");
            start_item(tx);
                tx.op               = sdram_transaction::OP_FULL_RANDOM;
                tx.bank             = cfg.bank;
                tx.row              = cfg.row;
                tx.start_column     = cfg.startColumn;
                tx.burstLength      = cfg.burstLength;
                tx.burst_type       = cfg.burstType;
                tx.cas              = cfg.casBits;
                tx.write_burst_mode = cfg.writeBurstMode;
                tx.data             = cfg.data;
                tx.byte_mask        = cfg.byteMask;
            finish_item(tx);

            s = "";
            foreach (tx.read_data[i])
                s = {s, $sformatf("%h ", tx.read_data[i])};
            `uvm_info("READBACK", $sformatf("Read back: %s", s), UVM_LOW)
        end
    endtask
endclass