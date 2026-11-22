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

typedef enum {
    CHECK_NORMAL_TRANS,
    CHECK_FULL_PAGE,
    CHECK_HZ,
    CHECK_INTERLEAVE,
    CHECK_TRUNC,
    CHECK_SLEEP,
    CHECK_RANDOM_TRANS
} cdv_specific_e;

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

    int randMode          = 1;          //0 - full random 1 - moje constraints
    int casLatency        = 2;    

    int cornerRows        = 0;
    int cornerCol         = 0;

    int curr_iter         = 0;
    int data_scope        = 5;
    int col_scope         = 2;
    int row_scope         = 2;
    int CAS_scope         = 2;
    int WB_scope          = 2;
    int BT_scope          = 2;
    int byte_scope        = 5;

    int selectedBank      = 4;

    rand int stop_point;
    
    int min_full_page_bytes = 200;
    int max_full_page_bytes = 511;

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

    cdv_specific_e curr_cdv   = CHECK_RANDOM_TRANS;
    rand test_e    curr_test;


        constraint c_test {
            if (curr_cdv == CHECK_NORMAL_TRANS) {
                curr_test dist {
                                TEST_BURST_RW_AP           := 1,
                                TEST_BURST_RW_NP           := 1
                                };
            }

            else if (curr_cdv == CHECK_FULL_PAGE) {
                curr_test == TEST_FULL_PAGE_RW_NP;   
            }

            else if (curr_cdv == CHECK_HZ) {
                curr_test dist {
                                TEST_BURST_RW_AP_HZ        := 1,
                                TEST_BURST_RW_NP_HZ        := 1
                                };
            }

            else if (curr_cdv == CHECK_INTERLEAVE) {
                curr_test dist {
                                TEST_BANK_INTERLEAVE_RW_AP := 1,
                                TEST_BANK_INTERLEAVE_RW_NP := 1
                                };    
            }

            else if (curr_cdv == CHECK_TRUNC) {
                curr_test dist {
                                TEST_WRITE_TRUNC           := 1,
                                TEST_READ_TRUNC            := 1
                                };      
            }

            else if (curr_cdv == CHECK_SLEEP) {
                curr_test dist {
                                TEST_POWER_DOWN            := 1,
                                TEST_SELF_REFRESH          := 1,
                                TEST_CLOCK_SUSPEND         := 1
                                };     
            }

            else if (curr_cdv == CHECK_RANDOM_TRANS) {
                curr_test dist {
                                TEST_BURST_RW_AP           := 1,
                                TEST_BURST_RW_NP           := 1,
                                TEST_BURST_RW_AP_HZ        := 1,
                                TEST_BURST_RW_NP_HZ        := 1,
                                TEST_FULL_PAGE_RW_NP       := 1,
                                TEST_BANK_INTERLEAVE_RW_AP := 1,
                                TEST_BANK_INTERLEAVE_RW_NP := 1, 
                                TEST_WRITE_TRUNC           := 1,
                                TEST_READ_TRUNC            := 1
                                };               
            }
        }

        constraint c_cas {
            if (CAS_scope == 0) {
                    casBits == 3'b010;
                }

            else if (CAS_scope == 1) {
                    casBits == 3'b011;
            }   

            else if (CAS_scope == 2) {
                    casBits inside {3'b010, 3'b011};
                } 
        }

        constraint c_wb_mode {
        if (curr_test == TEST_FULL_PAGE_RW_NP) {
                writeBurstMode == 1'b0;

            } else {
                if (WB_scope == 0) {
                        writeBurstMode == 1'b0;
                    }

                else if (WB_scope == 1) {
                        writeBurstMode == 1'b1;
                    }  

                else if (WB_scope == 2) {
                        writeBurstMode inside {1'b0, 1'b1};
                    }
            }  
        }

        constraint c_burst_length {
            if (curr_test == TEST_FULL_PAGE_RW_NP) {
                burstLength == 0;

            } else {
                if (byte_scope == 0) {
                        burstLength == 1;
                    }

                else if (byte_scope == 1) {
                        burstLength == 2;
                    }  

                else if (byte_scope == 2) {
                        burstLength == 4;
                    }

                else if (byte_scope == 3) {
                        burstLength == 8;
                    }    
                else if (byte_scope == 4){
                        burstLength inside {1, 2, 4, 8};
                    }               
            }
        }

        constraint c_burst_size {
            if (burstLength == 0) {
                burstSize inside {[min_full_page_bytes:max_full_page_bytes]};
            } else {
                if (writeBurstMode == 1'b1) burstSize == 1;
                else burstSize == burstLength;
            }
        }

        constraint c_burst_type {
            if (burstLength == 0) {
                burstType == 1'b0;
            } else {
                if (BT_scope == 0) {
                    burstType == 1'b0;
                }

                else if (BT_scope == 1) {
                    burstType == 1'b1;
                }  

                else if (BT_scope == 2) {
                    burstType inside {1'b0, 1'b1};
                }
            }
        }
            
        constraint c_bank {
            if (selectedBank == 0) {
                               bank == 2'b00;
                               bank2 dist {2'b01 := 1, 2'b10 := 1, 2'b11 := 1};
                               }

            else if (selectedBank == 1) {
                               bank == 2'b01;
                               bank2 dist {2'b00 := 1, 2'b10 := 1, 2'b11 := 1};
                               }

            else if (selectedBank == 2) {
                               bank == 2'b10;
                               bank2 dist {2'b00 := 1, 2'b01 := 1, 2'b11 := 1};
                               }

            else if (selectedBank == 3) {
                               bank == 2'b11;
                               bank2 dist {2'b00 := 1, 2'b01 := 1, 2'b10 := 1};
                               }

            else if (selectedBank == 4) {
                               bank  inside {2'b00, 2'b01, 2'b10, 2'b11};
                               bank2 inside {2'b00, 2'b01, 2'b10, 2'b11};
                               }
            bank != bank2;
        }

        constraint c_row {
            if (row_scope == 0) {
                row inside {[12'h000:12'h3FF]};
                }

            else if (row_scope == 1) {
                row inside {[12'h400:12'h7FF]};
                }

            else if (row_scope == 2) {
                row inside {[12'h800:12'hBFF]};
                }
            
            else if (row_scope == 3) {
                row inside {[12'hC00:12'hFFF]};
                }        

            else if (row_scope == 2) {
                row inside {[12'h000:12'hFFF]};
                }
        }

        constraint c_column {
            if (col_scope == 0) {
                startColumn inside {[9'h000:9'h0FF]};
                }

            else if (col_scope == 1) {
                startColumn inside {[9'h100:9'h1FF]};
                }

            else if (col_scope == 2) {
                startColumn inside {[9'h000:9'h1FF]};
                }
        }

        constraint c_data_size { data.size() == burstSize; }

        constraint c_data {
           if (data_scope == 0) {
                foreach (data[i]) data[i] inside {[16'h0001:16'h3FFF]};
           }

           else if (data_scope == 1) {
                foreach (data[i]) data[i] inside {[16'h4000:16'h7FFF]};
           }

           else if (data_scope == 2) {
                foreach (data[i]) data[i] inside {[16'h8000:16'hBFFF]};
           }

           else if (data_scope == 3) {
                foreach (data[i]) data[i] inside {[16'hC000:16'hFFFE]};
           }

           else if (data_scope == 4) {
                foreach (data[i]) data[i] dist {16'hAAAA := 1, 16'h5555 := 1, 16'h0000 := 1, 16'hFFFF := 1,
                                                16'h0001 := 1, 16'h0002 := 1, 16'h0004 := 1, 16'h0008 := 1,
                                                16'h0010 := 1, 16'h0020 := 1, 16'h0040 := 1, 16'h0080 := 1,
                                                16'h0100 := 1, 16'h0200 := 1, 16'h0400 := 1, 16'h0800 := 1,
                                                16'h1000 := 1, 16'h2000 := 1, 16'h4000 := 1, 16'h8000 := 1};
           }

           else if (data_scope == 5) {
                foreach (data[i]) data[i] inside {[16'h0000:16'hFFFF]};
           }
        }

        constraint c_byte_mask_size { byteMask.size() == burstSize; }

        constraint c_byte_mask {
            if (curr_test == TEST_BURST_RW_AP_HZ || curr_test == TEST_BURST_RW_NP_HZ) foreach (byteMask[i]) byteMask[i] == 2'b00;
            else foreach (byteMask[i]) byteMask[i] dist {2'b00 := 1, 2'b01 := 1, 2'b10 := 1, 2'b11 := 1};
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
