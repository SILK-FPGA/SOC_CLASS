#include "Vread_avalon_sdr.h"
#include "verilated.h"
#include "verilated_fst_c.h" 
#include <iostream>
#include <cstdlib>
#include <ctime>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 

    Vread_avalon_sdr* dut = new Vread_avalon_sdr;
    
    
    VerilatedFstC* tfp = new VerilatedFstC;
    dut->trace(tfp, 99);
    tfp->open("waveform.fst");

    // Initialize inputs
    dut->clk = 0;
    dut->reset = 1;
    dut->read_start_i = 0;
    dut->avm_m0_waitrequest = 0;
    dut->avm_m0_readdatavalid = 0;
    for (int i = 0; i < 8; i++) dut->avm_m0_readdata[i] = 0;

    uint64_t sim_time = 0;
    std::srand(std::time(nullptr));

    // SDRAM Model Internal States
    int pending_burst_beats = 0;
    int read_latency_timer = 0;
    uint32_t data_generator = 0xAA000000;
    bool cmd_accepted = false;

    auto tick = [&]() {
        // 1. POSEDGE
        dut->clk = 1;
        dut->eval();
        
        // CHỈ GHI WAVEFORM KHI ĐÃ TUA QUA 66,999,990 CHU KỲ
        if ((sim_time / 2) > 66999990) tfp->dump(sim_time); 
        sim_time++;

        // 2. NEGEDGE
        dut->clk = 0;
        dut->eval();

        dut->avm_m0_waitrequest = (std::rand() % 100 < 30) ? 1 : 0;

        if (dut->avm_m0_read && !dut->avm_m0_waitrequest && !cmd_accepted) {
            pending_burst_beats = dut->avm_m0_burstcount; 
            read_latency_timer = (std::rand() % 10) + 5; 
            cmd_accepted = true;
        } else if (!dut->avm_m0_read) {
            cmd_accepted = false;
        }

        dut->avm_m0_readdatavalid = 0; 
        
        if (pending_burst_beats > 0) {
            if (read_latency_timer > 0) {
                read_latency_timer--; 
            } else {
                if (std::rand() % 100 < 60) {
                    dut->avm_m0_readdatavalid = 1;
                    for (int i = 0; i < 8; i++) {
                        dut->avm_m0_readdata[i] = data_generator + i;
                    }
                    data_generator += 0x10;
                    pending_burst_beats--;
                }
            }
        }
        
        // CHỈ GHI WAVEFORM KHI ĐÃ QUA 66,999,990 CHU KỲ
        if ((sim_time / 2) > 66999990) tfp->dump(sim_time);
        sim_time++;
    };

    std::cout << "[TEST] Simulation Started.\n";

    for (int i = 0; i < 20; i++) tick();
    dut->reset = 0;
    for (int i = 0; i < 20; i++) tick();

    std::cout << "[TEST] Asserting read_start_i trigger...\n";
    dut->read_start_i = 1;
    tick();
    dut->read_start_i = 0;

    std::cout << "[TEST] Fast-forwarding through 67,000,000 cycle READ_DELAY... (Please wait)\n";
    while (dut->avm_m0_read == 0) {
        tick();
        if ((sim_time / 2) % 10000000 == 0) {
            std::cout << "[TEST] Elapsed time: " << (sim_time / 2) << " cycles...\n";
        }
        if ((sim_time / 2) > 70000000) {
            std::cout << "[FATAL ERROR] Timeout! DUT never asserted avm_m0_read.\n";
            break;
        }
    }

    std::cout << "[TEST] DUT exited delay loop. avm_m0_read asserted!\n";

    int timeout = 0;
    while (!dut->read_done_o && timeout < 2000) {
        tick();
        timeout++;
    }

    
    for (int i = 0; i < 20; i++) tick();

    if (dut->read_done_o) {
        std::cout << "[TEST] SUCCESS: read_done_o asserted! FSM reached READ_STOP.\n";
    }

   
    tfp->close(); 
    dut->final();
    delete dut;
    delete tfp;
    std::cout << "[TEST] Simulation Finished.\n";

    return 0;
}
