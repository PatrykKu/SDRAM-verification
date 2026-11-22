typedef enum {
    TEST_BURST_RW_AP,
    TEST_BURST_RW_NP,
    TEST_BURST_RW_AP_HZ,
    TEST_BURST_RW_NP_HZ,
    TEST_FULL_PAGE_RW_NP,
    TEST_BANK_INTERLEAVE_RW_AP, 
    TEST_BANK_INTERLEAVE_RW_NP, 
    TEST_WRITE_TRUNC,
    TEST_READ_TRUNC,
    TEST_POWER_DOWN,
    TEST_SELF_REFRESH,
    TEST_CLOCK_SUSPEND         
} test_e;

class sdram_cfg extends uvm_object;
    rand bit [2:0]  casBits;            // tylko CL2 (010) lub CL3 (011)
    rand int        burstLength;        // 1, 2, 4, 8, 0 - full page
    rand bit        writeBurstMode;     // 0 = burst write 1 = write 1 byte
    rand int        burstSize; 
    rand bit        burstType;          // 0 = sequential, 1 = interleaved
    rand bit [1:0]  bank;               // 0..3
    rand bit [1:0]  bank2;
    rand bit [11:0] row;                // dowolny wiersz
    rand bit [8:0]  startColumn;        // dowlona kolumna
    rand bit [15:0] data [];            //dane
    rand bit [1:0]  byteMask [];        //maska danych

    int randMode          = 0;          //0 - full random 1 - moje constraints
    int casLatency        = 2;    

    int cornerRows        = 1;
    int cornerCol         = 1;
    int cornerData        = 0;

    rand int data_idx;
    rand int row_idx;
    rand int col_idx; 
    rand int stop_point;
    
    int min_full_page_bytes = 17;
    int max_full_page_bytes = 18;

    real tPU  = 100000;  //Czas przygotowania
    real tCK  = 7;       //Cykl zegarowy
    real tCMS = 1.5;     //CMD setup time (min)
    real tCMH = 0.8;     //CMD hold time (min)
    real tAS  = 1.5;     //ADDR/BANK setup time (min)
    real tAH  = 0.8;     //ADDR/BANK hold time (min)
    real tCKS = 2;       //CKE setup time (min)
    real tCKH = 0.8;     //CKE hold time (min)
    real tDS  = 1.5;     //Data-in setup time
    real tDH  = 0.8;     //Data-in hold time 
    real tMRD = 14;      //LMR to active or high (2*tck)
    real tRP  = 15;      //Okno komendy Precharge
    real tRFC = 66;      //Okres auto refresh
    real tRAS = 45;      //Active to Precharge
    real tWR  = 15;      //Write recovery
    real tRCD = 20;      //Active to Read/Write

    rand test_e curr_test;
    rand test_e test_after_trunc;

    constraint c_test {
            if (randMode == 1) {
                curr_test dist {
                    TEST_BURST_RW_AP           := 1,
                    TEST_BURST_RW_NP           := 1,
                    TEST_BURST_RW_AP_HZ        := 1,
                    TEST_BURST_RW_NP_HZ        := 1,
                    TEST_FULL_PAGE_RW_NP       := 1,
                    TEST_BANK_INTERLEAVE_RW_AP := 1,
                    TEST_BANK_INTERLEAVE_RW_NP := 1, 
                    TEST_WRITE_TRUNC           := 1,
                    TEST_READ_TRUNC            := 1,
                    TEST_POWER_DOWN            := 1,
                    TEST_SELF_REFRESH          := 1,
                    TEST_CLOCK_SUSPEND         := 1
                };
            } else {
                curr_test dist {
                    TEST_BURST_RW_AP           := 1,
                    TEST_BURST_RW_NP           := 1,
                    TEST_BURST_RW_AP_HZ        := 1,
                    TEST_BURST_RW_NP_HZ        := 1,
                    TEST_FULL_PAGE_RW_NP       := 1,
                    TEST_BANK_INTERLEAVE_RW_AP := 1,
                    TEST_BANK_INTERLEAVE_RW_NP := 1,
                    TEST_WRITE_TRUNC           := 1,
                    TEST_READ_TRUNC            := 1,
                    TEST_POWER_DOWN            := 1,
                    TEST_SELF_REFRESH          := 1,
                    TEST_CLOCK_SUSPEND         := 1

                };
            }
        }

        constraint c_cas {
            if (randMode == 1) casBits dist {3'b010 := 1, 3'b011 := 1};
            else               casBits inside {3'b010, 3'b011};
        }

        constraint c_wb_mode {
            if (randMode == 1) writeBurstMode dist {1'b0 := 1, 1'b1 := 1};
            else               writeBurstMode inside {1'b0, 1'b1};
        }  

        constraint c_burst_length {
            if (randMode == 1) burstLength dist {1 := 1, 2 := 1, 4 := 1, 8 := 1};
            else               burstLength inside {1, 2, 4, 8, 0};
        }
        

        constraint c_burst_size {
            if (burstLength == 0) {
                if (randMode == 1) burstSize inside {[min_full_page_bytes:max_full_page_bytes]};
                else               burstSize inside {[1:512]};
            } else {
                if (writeBurstMode == 1'b1) burstSize == 1;
                else burstSize == burstLength;
            }
        }

        constraint c_burst_type {
            if (randMode == 1) burstType dist {1'b0 := 1, 1'b1 := 1};
            else               burstType inside {1'b0, 1'b1};
        }
            
        constraint c_bank {
            if (randMode == 1) {
                               bank  dist {2'b00 := 0, 2'b01 := 1, 2'b10 := 1, 2'b11 := 0};
                               bank2 dist {2'b00 := 1, 2'b01 := 1, 2'b10 := 1, 2'b11 := 1};
                               }

            else               {
                               bank  inside {2'b00, 2'b01, 2'b10, 2'b11};
                               bank2 inside {2'b00, 2'b01, 2'b10, 2'b11};
                               }

            bank != bank2;
        }

        constraint c_drc_limits {
            if (randMode == 1) {
                data_idx dist {  
                    0 := 1,  1 := 1,  2 := 1,  3 := 1,  4 := 1,  5 := 1,  6 := 1,  7 := 1,
                    8 := 1,  9 := 1, 10 := 1, 11 := 1, 12 := 1, 13 := 1, 14 := 1, 15 := 1,
                   16 := 1, 17 := 1, 18 := 1, 19 := 1, 20 := 1, 21 := 1, 22 := 1, 23 := 1,
                   24 := 1, 25 := 1, 26 := 1, 27 := 1, 28 := 1, 29 := 1, 30 := 1, 31 := 1
                };

                row_idx  dist {    
                    0 := 1,  1 := 1,  2 := 1,  3 := 1,  4 := 1,  5 := 1,  6 := 1,  7 := 1,
                    8 := 1,  9 := 1, 10 := 1, 11 := 1, 12 := 1, 13 := 1, 14 := 1, 15 := 1,
                   16 := 1, 17 := 1, 18 := 1, 19 := 1, 20 := 1
                };

                col_idx  dist {  
                    0 := 1,  1 := 1,  2 := 1,  3 := 1,  4 := 1,  5 := 1,  6 := 1,  7 := 1,
                    8 := 1,  9 := 1, 10 := 1
                };
            } else {
                data_idx inside {[0:31]};
                row_idx  inside {[0:20]};
                col_idx  inside {[0:10]};
            }
        }

        constraint c_row {
            if (randMode == 1) {
                if (cornerRows == 0) {
                    if (row_idx == 20) row inside {[4000 : 4095]}; 
                    else               row inside {[row_idx * 200 : (row_idx * 200) + 199]};
                    }
                else
                    {
                                       row dist   {12'h000 := 1, 12'hFFF := 1};
                    }
            } else {
                row inside {[12'h000 : 12'hFFF]};
            }
        }

        constraint c_column {
            if (randMode == 1) {
                if (cornerCol == 0) {
                    if (col_idx == 10) startColumn inside {[470 : 511]}; 
                    else               startColumn inside {[col_idx * 47 : (col_idx * 47) + 46]};
                    }
                else 
                    {
                                       startColumn dist   {9'h000 := 1, 9'h1FF := 1};
                    }
            } else {
                startColumn inside {[9'h000 : 9'h1FF]};
            }
        }

        constraint c_data_size { data.size() == burstSize; }

        constraint c_data {
            if (randMode == 1) {
                if (cornerData == 0) {
                    foreach (data[i]) data[i] inside {[data_idx * 2048 : (data_idx * 2048) + 2047]}; 
                }
                else {
                     foreach (data[i]) data[i] dist {16'hAAAA := 0, 16'h5555 := 0, 16'h0000 := 0, 16'hFFFF := 0,
                                                     16'h0001 := 1, 16'h0002 := 1, 16'h0004 := 1, 16'h0008 := 0,
                                                     16'h0010 := 0, 16'h0020 := 0, 16'h0040 := 0, 16'h0080 := 0,
                                                     16'h0100 := 0, 16'h0200 := 0, 16'h0400 := 1, 16'h0800 := 0,
                                                     16'h1000 := 0, 16'h2000 := 0, 16'h4000 := 1, 16'h8000 := 0};
                    }
            } else {
                foreach (data[i]) data[i] inside {[16'h0000 : 16'hFFFF]};
            }
        }

        constraint c_byte_mask_size { byteMask.size() == burstSize; }

        constraint c_byte_mask {
            foreach (byteMask[i]) byteMask[i] inside {2'b00, 2'b01, 2'b10, 2'b11};
            
        }

        constraint c_stop_point{
            stop_point inside {[1:7]};
            stop_point <= burstSize;    
        }
    
    `uvm_object_utils(sdram_cfg)

    function void post_randomize();
        if (casBits == 3'b011) casLatency = 3;
        else if (casBits == 3'b010) casLatency = 2;
    endfunction

    function new(string name = "sdram_cfg");
        super.new(name);
        // domyslne wartosci
        casBits      = 3'b010;
        casLatency   = 2;
        burstLength  = 8;
        burstType    = 1'b0;
        bank         = 2'b01;
        row          = 12'h090;
        startColumn  = 9'h030;
    endfunction

endclass
