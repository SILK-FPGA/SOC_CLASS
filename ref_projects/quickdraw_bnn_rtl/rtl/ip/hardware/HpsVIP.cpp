#include "HpsVIP.h"
#include <iostream>
#include <iomanip>

extern const char* class_names[10];

void HpsVIP::trigger_start(uint8_t& start_signal, std::function<void()> tick_fn) {
    std::cout << "[HPS VIP] Triggering read_start_i = 1...\n";
    start_signal = 1;
    for (int i = 0; i < 5; i++) tick_fn(); // Kéo giãn 5 chu kỳ
    start_signal = 0;
}

bool HpsVIP::wait_and_profile(
    uint32_t& result_word, std::function<void()> tick_fn, 
    uint32_t max_timeout, uint32_t target_delay_cycles, 
    uint32_t& current_clock_cycles, bool& enable_dump) 
{
    std::cout << "[HPS VIP] Waiting for AI Result (Delay = " << target_delay_cycles << " cycles)...\n";
    
    while (current_clock_cycles < max_timeout) {
        
      
        if (current_clock_cycles > target_delay_cycles - 100) enable_dump = true;

        if (current_clock_cycles % 10000 == 0 && current_clock_cycles > 0) {
            std::cout << "[TEST] Simulated " << current_clock_cycles << " clocks...\n";
        }

        tick_fn();
        
        if ((result_word >> 31) & 1U) { 
            uint32_t cls = result_word & 0xFU;
            int active_cycles = current_clock_cycles - target_delay_cycles;
            
            std::cout << "\n+==========================================================+\n";
            std::cout << "|                 VERILATOR CO-SIMULATION                  |\n";
            std::cout << "+==========================================================+\n";
            std::cout << "|   CLASS ID     : " << std::left << std::setw(38) << cls << "|\n";
            if (cls < 10)
                std::cout << "|   CLASS NAME   : " << std::left << std::setw(38) << class_names[cls] << "|\n";
            std::cout << "|   Result word  : 0x" << std::hex << std::setw(8) << std::setfill('0') << result_word << std::dec << std::setfill(' ') << std::setw(28) << " |\n";
            std::cout << "+----------------------------------------------------------+\n";
            std::cout << "|   TOTAL CLOCKS : " << std::dec << std::left << std::setw(38) << current_clock_cycles << "|\n";
            std::cout << "|   AI INFERENCE : " << std::left << std::setw(38) << active_cycles << "|\n";
            std::cout << "+==========================================================+\n\n";
            return true;
        }
    }
    std::cout << "ERROR: Timeout! No Valid signal received.\n";
    return false;
}
