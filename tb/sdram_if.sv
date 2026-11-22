interface sdram_if;
  bit          CLK;
  bit          CKE;
  bit          CS;
  bit          WE;
  bit          CAS;
  bit          RAS;
  bit   [1:0]  BA;
  bit   [12:0] ADDR;
  bit   [1:0]  DQM;
  wire  [15:0] DQ;

  //logika do dq
  bit   [15:0] dq_out;
  bit          dq_oi;
  assign DQ  = dq_oi ? dq_out : 16'hZZZZ;
endinterface
