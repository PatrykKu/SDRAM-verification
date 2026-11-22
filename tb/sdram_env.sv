class sdram_env extends uvm_env;
    `uvm_component_utils(sdram_env)

    sdram_driver         drv;
    sdram_sequencer      sqr;
    sdram_monitor        mon;
    sdram_scoreboard     scb;
    sdram_coverage_ddor  cov;

    function new(string name = "sdram_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = sdram_driver         ::type_id::create("drv", this);
        sqr = sdram_sequencer      ::type_id::create("sqr", this);
        mon = sdram_monitor        ::type_id::create("mon", this);
        scb = sdram_scoreboard     ::type_id::create("scb", this);
        cov = sdram_coverage_ddor  ::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
        mon.ap.connect(scb.ap_imp);
        mon.ap.connect(cov.analysis_export);
    endfunction
endclass