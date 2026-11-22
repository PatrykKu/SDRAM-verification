class sdram_transaction extends uvm_sequence_item;

    sdram_cfg cfg;

    typedef enum {
        OP_CI,
        OP_INIT,
        OP_PREP,
        OP_WRITE_AP,
        OP_WRITE_NP,
        OP_READ_AP,
        OP_READ_NP,
        OP_READ_AP_HZ,
        OP_READ_NP_HZ,
        OP_WRITE_SUSPEND,
        OP_READ_SUSPEND,
        OP_WRITE_TRUNC,
        OP_READ_TRUNC,
        OP_ACTIVE,
        OP_DEAT_AP,
        OP_DEAT_NP_ALL,
        OP_DEAT_NP_BANK,
        OP_BURST_TERM,
        OP_ENTER_PD,
        OP_EXIT_PD,
        OP_SELF_REFRESH,
        OP_FULL_RANDOM
    } sdram_op_e;

    rand sdram_op_e   op;
    rand bit [1:0]    bank;
    rand bit [11:0]   row;
    rand bit [8:0]    start_column;
    rand int          burstLength;
    rand int          burstSize;
    rand bit          burst_type;
    rand bit [2:0]    cas;
    rand bit          write_burst_mode;
    rand bit [15:0]   data       [];
    rand bit [1:0]    byte_mask  [];
    bit      [15:0]   read_data  [];
    rand int          stop_point;

    `uvm_object_utils(sdram_transaction)

    function new(string name = "sdram_transaction");
        super.new(name);
    endfunction

endclass