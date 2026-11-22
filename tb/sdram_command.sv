class sdram_command;
  bit          cs;
  bit          ras;
  bit          cas;
  bit          we;
  bit  [1:0]   dqm;
  bit  [1:0]   ba;
  bit  [11:0]  addr;
  bit  [15:0]  dq;
  bit          dq_en;
endclass

class sdram_cmd_types;

  static function sdram_command command_inhibit();
    command_inhibit = new();
    command_inhibit.cs=1; command_inhibit.ras=0; command_inhibit.cas=0; command_inhibit.we=0;
  endfunction

  static function sdram_command nop();
    nop = new();
    nop.cs=0; nop.ras=1; nop.cas=1; nop.we=1;
  endfunction

  static function sdram_command active(bit [1:0] bank, bit [11:0] row);
    active = new();
    active.cs=0; active.ras=0; active.cas=1; active.we=1;
    active.ba=bank; active.addr=row;
  endfunction

  static function sdram_command read(bit [1:0] bank, bit [11:0] addr_with_ap);
    read = new();
    read.cs=0; read.ras=1; read.cas=0; read.we=1;
    read.ba=bank; read.addr=addr_with_ap;
  endfunction

  static function sdram_command write(bit [1:0] bank, bit [11:0] addr_with_ap,
                                       bit [15:0] data, bit [1:0] mask);
    write = new();
    write.cs=0; write.ras=1; write.cas=0; write.we=0;
    write.ba=bank; write.addr=addr_with_ap;
    write.dq=data; write.dqm=mask; write.dq_en=1;
  endfunction

  static function sdram_command nop_after_write(bit [15:0] data, bit [1:0] mask);
    nop_after_write = new();
    nop_after_write.cs=0; nop_after_write.ras=1; nop_after_write.cas=1; nop_after_write.we=1;
    nop_after_write.dq=data; nop_after_write.dqm=mask; nop_after_write.dq_en=1;
  endfunction

  static function sdram_command burst_terminate(bit [1:0] bank, bit [11:0] addr);
    burst_terminate = new();
    burst_terminate.cs=0; burst_terminate.ras=1; burst_terminate.cas=1; burst_terminate.we=0;
    burst_terminate.ba=bank; burst_terminate.addr=addr;
  endfunction

  static function sdram_command precharge_all();
    precharge_all = new();
    precharge_all.cs=0; precharge_all.ras=0; precharge_all.cas=1; precharge_all.we=0;
    precharge_all.addr = 12'h400;
  endfunction
  
 static function sdram_command precharge_bank(bit [1:0] bank);
    precharge_bank = new();
    precharge_bank.cs=0; precharge_bank.ras=0; precharge_bank.cas=1; precharge_bank.we=0;
    precharge_bank.ba = bank;
  endfunction

  static function sdram_command auto_refresh();
    auto_refresh = new();
    auto_refresh.cs=0; auto_refresh.ras=0; auto_refresh.cas=0; auto_refresh.we=1;
  endfunction

  static function sdram_command load_mode(bit [11:0] mode_bits);
    load_mode = new();
    load_mode.cs=0; load_mode.ras=0; load_mode.cas=0; load_mode.we=0;
    load_mode.addr = mode_bits;
  endfunction

endclass

class sdram_mode_register;
  bit       WB;
  bit [1:0] OpMode;
  bit [2:0] CAS;
  bit       burstType;
  bit [2:0] burstLength;

  function bit [11:0] to_bits();
    return {2'b00, WB, OpMode, CAS, burstType, burstLength};
  endfunction

  static function bit [2:0] burst_length_code(int bl);
    case (bl)
      0:       burst_length_code = 3'b111;
      1:       burst_length_code = 3'b000;
      2:       burst_length_code = 3'b001;
      4:       burst_length_code = 3'b010;
      8:       burst_length_code = 3'b011;
      default: burst_length_code = 3'b000;
    endcase
  endfunction

  static function int code_to_burst_length(bit [2:0] code);
    case (code)
        3'b000:  code_to_burst_length = 1;
        3'b001:  code_to_burst_length = 2;
        3'b010:  code_to_burst_length = 4;
        3'b011:  code_to_burst_length = 8;
        3'b111:  code_to_burst_length = 0;
        default: code_to_burst_length = 1;
    endcase
endfunction

  static function int cas_to_latency(bit [2:0] cas_bits);
    cas_to_latency = (cas_bits == 3'b010) ? 2 : 3;
  endfunction
endclass