#ifndef SDRAM_VIP_H
#define SDRAM_VIP_H

#include <stdint.h>
#include <vector>
#include <string>

class SdramVIP {
private:
    std::vector<uint8_t> memory;
    uint32_t base_addr;
    int read_latency_config;
    int current_latency;
    int pending_burst;
    uint32_t current_sdram_addr;

public:
    // Khởi tạo dung lượng và độ trễ
    SdramVIP(uint32_t base_phys, uint32_t size_bytes, int latency = 2);
    
    // Đọc file test
    bool load_txt_image(const std::string& path, uint32_t pixel_count);
    
    // Được gọi mỗi nhịp clock để giả lập hành vi Avalon Slave
    void eval(
        uint8_t avm_read,
        uint32_t avm_address,
        uint32_t avm_burstcount,
        uint8_t& avm_waitrequest,
        uint8_t& avm_readdatavalid,
        uint32_t* avm_readdata
    );
};

#endif
