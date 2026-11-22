`timescale 1ns/10ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import sdram_pkg::*;

module testbench;
    sdram_if vif();

    MEM memory (
        .clk   (vif.CLK),
        .cke   (vif.CKE),
        .csb   (vif.CS),
        .web   (vif.WE),
        .casb  (vif.CAS),
        .rasb  (vif.RAS),
        .ba    (vif.BA),
        .addr  (vif.ADDR),
        .dqm   (vif.DQM),
        .dq    (vif.DQ)
    );

    initial begin
        uvm_config_db#(virtual sdram_if)::set(null, "*", "vif", vif);

        $dumpfile("dump.vcd");
        $dumpvars(0, testbench);

        run_test();
    end

endmodule