#include "SdramVIP.h"
#include <iostream>

SdramVIP::SdramVIP(uint32_t base_phys, uint32_t size_bytes, int latency) {
    base_addr = base_phys;
    memory.resize(size_bytes, 0);
    read_latency_config = latency;
    current_latency = 0;
    pending_burst = 0;
    current_sdram_addr = 0;
}

bool SdramVIP::load_txt_image(const std::string& path, uint32_t pixel_count) {
    std::cout << "[SDRAM VIP] Reading image: " << path << "\n";
    FILE *fp = fopen(path.c_str(), "r");
    if (!fp) {
        std::cerr << "ERROR: cannot open " << path << "\n";
        return false;
    }
    int pixel_val, count = 0;
    while (count < pixel_count && fscanf(fp, "%d", &pixel_val) == 1) {
        if (pixel_val > 0) {
            memory[count >> 3] |= (uint8_t)(1u << (count & 7));
        }
        count++;
    }
    fclose(fp);
    std::cout << "[SDRAM VIP] Packed " << count << " pixels into Virtual SDRAM.\n";
    return count == pixel_count;
}

void SdramVIP::eval(
    uint8_t avm_read, uint32_t avm_address, uint32_t avm_burstcount,
    uint8_t& avm_waitrequest, uint8_t& avm_readdatavalid, uint32_t* avm_readdata) 
{
    avm_readdatavalid = 0;
    avm_waitrequest = 0; 
    
    // Nếu đang trong quá trình xử lý lệnh cũ, báo bận để khóa luồng
    if (pending_burst > 0) {
        avm_waitrequest = 1; 
    }

    // 1. Nhận lệnh (Chỉ nhận khi RAM đang rảnh)
    if (avm_read && pending_burst == 0) {
        pending_burst = avm_burstcount;
        current_latency = read_latency_config;
        current_sdram_addr = avm_address - base_addr;
        
        // CỐT LÕI Ở ĐÂY: Dù đã nhận lệnh nhưng chu kỳ hiện tại waitrequest VẪN PHẢI = 0
        // để mạch RTL bắt được và nhảy sang state READ_END.
    }

    // 2. Trả dữ liệu (Bơm liên tục đủ burst)
    if (pending_burst > 0) {
        if (current_latency > 0) {
            current_latency--; // Trừ dần độ trễ CAS Latency
        } else {
            avm_readdatavalid = 1; // Bắn cờ báo data hợp lệ
            
            // Ép 32 byte (256 bit) lên bus
            for (int w = 0; w < 8; w++) {
                uint32_t word = 0;
                for (int b = 0; b < 4; b++) {
                    if (current_sdram_addr + w*4 + b < memory.size()) {
                        word |= (memory[current_sdram_addr + w*4 + b] << (b * 8));
                    }
                }
                avm_readdata[w] = word;
            }
            
            current_sdram_addr += 32;
            pending_burst--;
        }
    }
}
