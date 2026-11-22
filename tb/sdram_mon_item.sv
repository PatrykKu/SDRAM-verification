typedef enum {
    CMD_NOP, 
    CMD_ACTIVE, 
    CMD_READ, 
    CMD_WRITE,
    CMD_PRECHARGE, 
    CMD_AUTO_REFRESH, 
    CMD_LOAD_MODE,
    CMD_INHIBIT, 
    CMD_BURST_TERMINATE,
    CMD_SELF_REFRESH,
    CMD_POWER_DOWN,
    CMD_UNKNOWN
} sdram_cmd_e;

class sdram_mon_item extends uvm_sequence_item;
	sdram_cmd_e curr_cmd;
	bit 		cs, ras, cas, we, cke;
	bit [1:0]   ba;
	bit [11:0]  addr;
	bit [15:0]  dq;
	bit [1:0]   dqm;

	`uvm_object_utils(sdram_mon_item)

	function new(string name = "sdram_mon_item");
		super.new(name);
	endfunction

endclass