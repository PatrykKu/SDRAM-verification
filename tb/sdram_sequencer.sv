class sdram_sequencer extends uvm_sequencer #(sdram_transaction);
    `uvm_component_utils(sdram_sequencer)

    function new(string name = "sdram_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass