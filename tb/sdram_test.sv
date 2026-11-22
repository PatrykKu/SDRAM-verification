class sdram_test extends uvm_test;
    `uvm_component_utils(sdram_test)

    sdram_env env;
    sdram_cfg cfg;

    function new(string name = "sdram_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = sdram_cfg::type_id::create("cfg");
        uvm_config_db#(sdram_cfg)::set(this, "*", "cfg", cfg);
        `uvm_info("USTAWIENIA",
                  $sformatf("Config: cas_bits=%b (CL%0d) burst=%0d tCK=%0.1f",
                            cfg.casBits, cfg.casLatency, cfg.burstLength, cfg.tCK),
                  UVM_LOW)
        env = sdram_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        sdram_test_sequence seq;
        phase.raise_objection(this);
        seq = sdram_test_sequence::type_id::create("seq");
        seq.start(env.sqr);
        phase.drop_objection(this);
    endtask
endclass