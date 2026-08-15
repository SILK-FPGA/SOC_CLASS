#ifndef HPS_VIP_H
#define HPS_VIP_H

#include <stdint.h>
#include <functional>

class HpsVIP {
public:
    // Cấp xung kích hoạt (Kéo dài 5 chu kỳ clock)
    static void trigger_start(uint8_t& start_signal, std::function<void()> tick_fn);
    
    // Chờ kết quả AI và Profiling thời gian
    static bool wait_and_profile(
        uint32_t& result_word, 
        std::function<void()> tick_fn, 
        uint32_t max_timeout,
        uint32_t target_delay_cycles,
        uint32_t& current_clock_cycles,
        bool& enable_dump
    );
};

#endif
