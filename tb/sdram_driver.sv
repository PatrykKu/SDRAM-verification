class sdram_driver extends uvm_driver #(sdram_transaction);
	`uvm_component_utils(sdram_driver)

	virtual sdram_if vif;
  sdram_cfg cfg;

	function new(string name = "sdram_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	//build_phase
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
    if(!uvm_config_db#(virtual sdram_if)::get(this, "", "vif", vif))
      	`uvm_fatal("NO_VIF", "Brak virtual interface")
    if (!uvm_config_db#(sdram_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("NO_CFG", "Brak sdram_cfg")
  endfunction

    sdram_command curr_cmd;

    task run_phase(uvm_phase phase);
    	sdram_transaction tx;
    	curr_cmd = sdram_cmd_types::nop();
    	vif.CLK   <= 0;
    	vif.CKE   <= 0;
    	vif.CS    <= 0;
    	vif.WE    <= 0;
    	vif.CAS   <= 0;
    	vif.RAS   <= 0;
    	vif.BA    <= 2'b00;
    	vif.ADDR  <= 12'b0;
    	vif.DQM   <= 2'b00;
    	vif.dq_out <= 16'h0;
    	vif.dq_oi <= 1;

    	forever begin
    		seq_item_port.get_next_item(tx);
    		drive_transaction(tx);
    		seq_item_port.item_done();
    	end
    endtask

    int suspend_idx_w;
    int suspend_idx_r;
    rand int command;
    
    task sendCommand(sdram_command c);
    	curr_cmd = c;
    endtask

    task drive_transaction(sdram_transaction tx);
    	case (tx.op)
        sdram_transaction::OP_CI:
          CommandInhibitStart();

    		sdram_transaction::OP_INIT:
    			Initialization();

    		sdram_transaction::OP_PREP:
    			PrepareMemory(tx);

    		sdram_transaction::OP_WRITE_AP:
    			BurstWriteAP(tx);

    		sdram_transaction::OP_WRITE_NP:
    			BurstWriteNP(tx);	

    		sdram_transaction::OP_READ_AP:
    			BurstReadAP(tx);

    		sdram_transaction::OP_READ_NP:
    			BurstReadNP(tx);

        sdram_transaction::OP_READ_AP_HZ:
          BurstReadAPHighZ(tx);

        sdram_transaction::OP_READ_NP_HZ:
          BurstReadNPHighZ(tx);

        sdram_transaction::OP_WRITE_SUSPEND:
          BurstWriteNPSuspend(tx);

        sdram_transaction::OP_READ_SUSPEND:
          BurstReadNPSuspend(tx);

        sdram_transaction::OP_WRITE_TRUNC:
          BurstWriteAPTrunc(tx);

        sdram_transaction::OP_READ_TRUNC:
          BurstReadAPTrunc(tx);

        sdram_transaction::OP_ACTIVE:
          ActiveAP(tx);  

    		sdram_transaction::OP_DEAT_AP:
    			DeactivateOpenRowAP();

    		sdram_transaction::OP_DEAT_NP_ALL:
    			DeactivateOpenRowNPAll();

        sdram_transaction::OP_DEAT_NP_BANK:
          DeactivateOpenRowNPBank(tx);

        sdram_transaction::OP_BURST_TERM:
          BurstTerminate(tx);

        sdram_transaction::OP_ENTER_PD:
          EnterPowerDown();

        sdram_transaction::OP_EXIT_PD:
          ExitPowerDown();

        sdram_transaction::OP_SELF_REFRESH:
          SelfRefresh();

        sdram_transaction::OP_FULL_RANDOM:
          FullRandom(tx);  

    		default:
    			`uvm_error("blad", "nieznana operacja")
    	endcase
    endtask

	task oneCLK();
		fork			
			begin // Komendy - tCMS
				#(cfg.tCK/2 - cfg.tCMS);
				vif.CS  <= curr_cmd.cs;
				vif.RAS <= curr_cmd.ras;
				vif.CAS <= curr_cmd.cas;
				vif.WE  <= curr_cmd.we;
				vif.DQM <= curr_cmd.dqm;
			end
			
			begin // Adres/Bank - tAS
				#(cfg.tCK/2 - cfg.tAS);
				vif.BA   <= curr_cmd.ba;
				vif.ADDR <= curr_cmd.addr;
			end
			
			begin // Dane - tDS
				#(cfg.tCK/2 - cfg.tDS);
				vif.dq_out <= curr_cmd.dq;
				vif.dq_oi  <= curr_cmd.dq_en;
			end
			
			begin // Zegar
				#(cfg.tCK/2);
				vif.CLK = 1;
				#(cfg.tCK/2);
				vif.CLK = 0;
			end
		join
	endtask

  task oneCLK_readHZ(output bit [15:0] out_data);
        fork            
            begin // Komendy - tCMS
                #(cfg.tCK/2 - cfg.tCMS);
                vif.CS  <= curr_cmd.cs;
                vif.RAS <= curr_cmd.ras;
                vif.CAS <= curr_cmd.cas;
                vif.WE  <= curr_cmd.we;
                vif.DQM <= curr_cmd.dqm;
            end
            
            begin // Adres/Bank - tAS
                #(cfg.tCK/2 - cfg.tAS);
                vif.BA   <= curr_cmd.ba;
                vif.ADDR <= curr_cmd.addr;
            end
            
            begin // Dane - tDS
                #(cfg.tCK/2 - cfg.tDS);
                vif.dq_out <= curr_cmd.dq;
                vif.dq_oi  <= curr_cmd.dq_en;
            end
            
            begin //Zegar i odczyt
                #(cfg.tCK/2);
                vif.CLK = 1;
                out_data = vif.DQ;
                #(cfg.tCK/2);
                vif.CLK = 0;
            end
        join
    endtask

	task Initialization();
	    #(cfg.tPU);
	    NOP();
	    vif.CKE = 1;
	    oneCLK();

	    PrechargeAll();
	    oneCLK();
	    NOP();
	    repeat (2) oneCLK();

	    AutoRefresh();
	    oneCLK();
	    NOP();
	    repeat (9) oneCLK();

	    AutoRefresh();
	    oneCLK();
	    NOP();
	    repeat (9) oneCLK();
  	endtask

  	task PrepareMemory(input sdram_transaction tx);
    	if (tx.burstLength != 0 && tx.burstLength != 1 && tx.burstLength != 2 &&
        	tx.burstLength != 4 && tx.burstLength != 8) begin
      		$display("Burst Length tylko 1, 2, 4, 8 albo 0(Full Page)!");
      		return;
    	end

    LMR(tx.write_burst_mode, 2'b00, tx.cas, tx.burst_type,
      sdram_mode_register::burst_length_code(tx.burstLength));
    oneCLK();
    NOP();
    repeat (2) oneCLK();

    Active(tx.bank, tx.row);
    oneCLK();
    NOP();
    repeat (2) oneCLK();
  endtask

  task ActiveAP(input sdram_transaction tx);
    Active(tx.bank, tx.row);
    oneCLK();
    NOP();
    repeat (3) oneCLK();
  endtask


  task DeactivateOpenRowNPAll();
    NOP();
    repeat ($ceil(cfg.tRAS / cfg.tCK)) oneCLK();
    PrechargeAll();
    oneCLK();
    NOP();
    repeat ($ceil(cfg.tRP / cfg.tCK)) oneCLK();
  endtask

  task DeactivateOpenRowNPBank(input sdram_transaction tx);
    NOP();
    repeat ($ceil(cfg.tRAS / cfg.tCK)) oneCLK();
    PrechargeBank(tx.bank);
    oneCLK();
    NOP();
    repeat ($ceil(cfg.tRP / cfg.tCK)) oneCLK();
  endtask

  task DeactivateOpenRowAP();
    NOP();
    repeat ($ceil((cfg.tRP + cfg.tWR + 14) / cfg.tCK)) oneCLK();
  endtask

  task BurstReadNP(input sdram_transaction tx);
    Read(tx.bank, {3'b000, tx.start_column});
    oneCLK();
    NOP();
    repeat ((cfg.casLatency - 1)) oneCLK();

    tx.read_data = new[tx.burstSize];

    for (int i = 0; i < (tx.burstSize); i++) begin
      #(cfg.tCK/2);
      vif.CLK = 1;
      tx.read_data[i] = vif.DQ;
      #(cfg.tCK/2);
      vif.CLK = 0;
    end

    if (tx.burstLength == 0) begin
      BurstTerminate(tx);
      oneCLK();
      NOP();
    end
  endtask

  task BurstReadAP(input sdram_transaction tx);
    Read(tx.bank, {3'b010, tx.start_column});
    oneCLK();
    NOP();
    repeat ((cfg.casLatency - 1)) oneCLK();

    tx.read_data = new[tx.burstSize];

    for (int i = 0; i < tx.burstSize; i++) begin
      #(cfg.tCK/2);
      vif.CLK = 1;
      tx.read_data[i] = vif.DQ;
      #(cfg.tCK/2);
      vif.CLK = 0;
    end
  endtask

task BurstReadNPHighZ(input sdram_transaction tx);
    tx.read_data = new[tx.burstSize];

    Read(tx.bank, {3'b000, tx.start_column});
    if (cfg.casLatency == 2) curr_cmd.dqm = tx.byte_mask[0];
    else                     curr_cmd.dqm = 2'b00;
    oneCLK();

    NOP();
    if (cfg.casLatency == 3)                 curr_cmd.dqm = tx.byte_mask[0];
    else if (tx.burstSize > 1)               curr_cmd.dqm = tx.byte_mask[1];
    else                                     curr_cmd.dqm = 2'b00;
    oneCLK();

    if (cfg.casLatency == 3) begin
        NOP();
        if (tx.burstSize > 1) curr_cmd.dqm = tx.byte_mask[1];
        else                  curr_cmd.dqm = 2'b00;
        oneCLK();
    end

    for (int i = 0; i < tx.burstSize; i++) begin
        NOP();
        if (i + cfg.casLatency < tx.burstSize)
            curr_cmd.dqm = tx.byte_mask[i + cfg.casLatency];
        else
            curr_cmd.dqm = 2'b00;

        oneCLK_readHZ(tx.read_data[i]);
    end

    if (tx.burstLength == 0) begin
      BurstTerminate(tx);
      oneCLK();
      NOP();
    end
  endtask

  task BurstReadAPHighZ(input sdram_transaction tx);
    tx.read_data = new[tx.burstSize];

    Read(tx.bank, {3'b010, tx.start_column});
    if (cfg.casLatency == 2) curr_cmd.dqm = tx.byte_mask[0];
    else                     curr_cmd.dqm = 2'b00;
    oneCLK();

    NOP();
    if (cfg.casLatency == 3)                 curr_cmd.dqm = tx.byte_mask[0];
    else if (tx.burstSize > 1)               curr_cmd.dqm = tx.byte_mask[1];
    else                                     curr_cmd.dqm = 2'b00;
    oneCLK();

    if (cfg.casLatency == 3) begin
        NOP();
        if (tx.burstSize > 1) curr_cmd.dqm = tx.byte_mask[1];
        else                  curr_cmd.dqm = 2'b00;
        oneCLK();
    end

    for (int i = 0; i < tx.burstSize; i++) begin
        NOP();
        if (i + cfg.casLatency < tx.burstSize)
            curr_cmd.dqm = tx.byte_mask[i + cfg.casLatency];
        else
            curr_cmd.dqm = 2'b00;

        oneCLK_readHZ(tx.read_data[i]);
    end
  endtask

  task BurstWriteNP(input sdram_transaction tx);

    Write(tx.bank, {3'b000, tx.start_column}, tx.data[0], tx.byte_mask[0]);
    oneCLK();

    for (int i = 1; i < tx.burstSize; i++) begin
      NOPAfterWrite(tx.data[i], tx.byte_mask[i]);
      oneCLK();
    end

    if (tx.burstLength == 0) begin
      BurstTerminate(tx);
      oneCLK();
      NOP();
    end

  endtask

  task BurstWriteAP(input sdram_transaction tx);

    Write(tx.bank, {3'b010, tx.start_column}, tx.data[0], tx.byte_mask[0]);
    oneCLK();

    for (int i = 1; i < tx.burstSize; i++) begin
      NOPAfterWrite(tx.data[i], tx.byte_mask[i]);
      oneCLK();
    end
    
  endtask

task BurstWriteNPSuspend(input sdram_transaction tx);
    suspend_idx_w = tx.burstSize / 2;

    for (int i = 0; i < tx.burstSize; i++) begin
      if (i == 0) Write(tx.bank, {3'b000, tx.start_column}, tx.data[0], tx.byte_mask[0]);
      else        NOPAfterWrite(tx.data[i], tx.byte_mask[i]);

      if (i == suspend_idx_w - 1) begin
          vif.CKE = 1'b0;
      end

      oneCLK();

      if (i == suspend_idx_w - 1) begin
          `uvm_info("WRITE", "CLK SUSPEND (CKE=0)", UVM_LOW)
          
          NOPAfterWrite(tx.data[suspend_idx_w], tx.byte_mask[suspend_idx_w]);
          repeat(3) oneCLK();
          
          vif.CKE = 1'b1;
          oneCLK();
          `uvm_info("WRITE", "CLK SUSPEND END (CKE=1)", UVM_LOW)
      end
    end

    if (tx.burstLength == 0) begin
      BurstTerminate(tx);
      oneCLK();
      NOP();
    end
  endtask

  task BurstReadNPSuspend(input sdram_transaction tx);
    tx.read_data = new[tx.burstSize];
    suspend_idx_r = tx.burstSize / 2;

    Read(tx.bank, {3'b000, tx.start_column});
    curr_cmd.dqm = 2'b00;
    oneCLK();

    NOP();
    oneCLK();

    if (cfg.casLatency == 3) begin
        NOP();
        oneCLK();
    end

    for (int i = 0; i < tx.burstSize; i++) begin
        NOP();
        curr_cmd.dqm = 2'b00;

        if (i == suspend_idx_r - 1) begin
            vif.CKE = 1'b0;
        end

        oneCLK_readHZ(tx.read_data[i]);

        if (i == suspend_idx_r - 1) begin
            `uvm_info("READ", "CLK SUSPEND(CKE=0)", UVM_LOW)
            repeat(3) oneCLK(); 
            
            vif.CKE = 1'b1;
            oneCLK(); 
            `uvm_info("READ", "CLK SUSPEND END (CKE=1)", UVM_LOW)
        end
    end

    if (tx.burstLength == 0) begin
      BurstTerminate(tx);
      oneCLK();
      NOP();
    end
  endtask

  task BurstWriteAPTrunc(input sdram_transaction tx);
    Write(tx.bank, {3'b010, tx.start_column}, tx.data[0], tx.byte_mask[0]);
    oneCLK();

    for (int i = 1; i < tx.stop_point; i++) begin
      NOPAfterWrite(tx.data[i], tx.byte_mask[i]);
      oneCLK();
    end
  endtask

  task BurstReadAPTrunc(input sdram_transaction tx);
    int total_cycles = cfg.casLatency + tx.stop_point;
    tx.read_data = new[tx.stop_point];

    for (int c = 0; c < total_cycles; c++) begin
        if (c == 0) Read(tx.bank, {3'b010, tx.start_column});
        else NOP();

        if (c >= total_cycles - 2) curr_cmd.dqm = 2'b11;
        else                       curr_cmd.dqm = 2'b00;

        if (c >= cfg.casLatency) begin
            oneCLK_readHZ(tx.read_data[c - cfg.casLatency]);
        end else begin
            oneCLK();
        end
    end
    curr_cmd.dqm = 2'b00;
    oneCLK();
  endtask

  task CommandInhibitStart();
    CommandInhibit();
    oneCLK();
  endtask

    task BurstTerminate(input sdram_transaction tx);
      sendCommand(sdram_cmd_types::burst_terminate(tx.bank, tx.row));
    endtask

  	task CommandInhibit();
    	sendCommand(sdram_cmd_types::command_inhibit());
  	endtask

  	task NOP();
    	sendCommand(sdram_cmd_types::nop());
  	endtask

  	task Active(input bit [1:0] bank, [11:0] addr);
    	sendCommand(sdram_cmd_types::active(bank, addr));
  	endtask

  	task Read(input bit [1:0] bank, [11:0] addr);
    	sendCommand(sdram_cmd_types::read(bank, addr));
  	endtask

  	task Write(input bit [1:0] bank, [11:0] addr, [15:0] data, [1:0] byteMask);
    	sendCommand(sdram_cmd_types::write(bank, addr, data, byteMask));
  	endtask

  	task NOPAfterWrite(input bit [15:0] data, [1:0] byteMask);
    	sendCommand(sdram_cmd_types::nop_after_write(data, byteMask));
  	endtask

  	task PrechargeAll();
    	sendCommand(sdram_cmd_types::precharge_all());
  	endtask

  	task PrechargeBank(input bit [1:0] bank);
    	sendCommand(sdram_cmd_types::precharge_bank(bank));
  	endtask

  	task AutoRefresh();
    	sendCommand(sdram_cmd_types::auto_refresh());
  	endtask

  	task LMR(input bit       WB,
           input bit [1:0] OpMode,
           input bit [2:0] CAS,
           input bit       burstType,
           input bit [2:0] burstLength);
    	sdram_mode_register mr;
    	mr = new();
    	mr.WB          = WB;
    	mr.OpMode      = OpMode;
    	mr.CAS         = CAS;
    	mr.burstType   = burstType;
    	mr.burstLength = burstLength;
    	sendCommand(sdram_cmd_types::load_mode(mr.to_bits()));
  	endtask

    task EnterPowerDown();
      NOP();
      oneCLK();

      #(cfg.tCK/2 - cfg.tCKS);
      vif.CKE    = 1'b0;
      #(cfg.tCKS);
      vif.CLK    = 1'b1;
      #(cfg.tCK/2); 
      vif.CLK    = 1'b0;

      repeat (10) oneCLK(); //nie wiecej niz 64ms
    endtask

    task ExitPowerDown();
      vif.CKE    = 1'b1;
      NOP();
      oneCLK();
    endtask

    task PowerDown();
      NOP();
      oneCLK();

      #(cfg.tCK/2 - cfg.tCKS);
      vif.CKE    = 1'b0;
      #(cfg.tCKS);
      vif.CLK    = 1'b1;
      #(cfg.tCK/2); 
      vif.CLK    = 1'b0;

      repeat (10) oneCLK();

      vif.CKE    = 1'b1;
      NOP();
      oneCLK();
    endtask

    task SelfRefresh();
      repeat (2) oneCLK();
      NOP();
      oneCLK();

      vif.CKE    = 1'b0;
      AutoRefresh();
      oneCLK();

      #(cfg.tCK*10);

      oneCLK();
      vif.CKE    = 1'b1;
      NOP();
      oneCLK();
    endtask

    task FullRandom(input sdram_transaction tx);
      command = $urandom_range(0, 11);

      case (command)
        0:begin
          CommandInhibit();
          oneCLK();
        end

        1:begin
          NOP();
          oneCLK();
        end

        2:begin
          Active(tx.bank, tx.row);
          oneCLK();
          NOP();
          repeat (3) oneCLK();
        end

        3:begin
          PrechargeAll();
        end

        4:begin
          Write(tx.bank, {3'b000, tx.start_column}, tx.data[0], tx.byte_mask[0]);
          oneCLK();
        end

        5: begin
          Read(tx.bank, {3'b000, tx.start_column});
          oneCLK();
        end

        6:begin
          Write(tx.bank, {3'b010, tx.start_column}, tx.data[0], tx.byte_mask[0]);
          oneCLK();
        end

        7: begin
          Read(tx.bank, {3'b010, tx.start_column});
          oneCLK();
        end

        8: begin
          PowerDown();
        end

        9: begin
          SelfRefresh();
        end

        10:begin
          LMR(tx.write_burst_mode, 2'b00, tx.cas, tx.burst_type,
          sdram_mode_register::burst_length_code(tx.burstLength));
          oneCLK();
        end

        11:begin
            AutoRefresh();
            oneCLK();
        end
      endcase
    endtask
endclass

