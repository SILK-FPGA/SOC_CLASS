#include "Vbnn_soc_wrapper.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "SdramVIP.h"
#include "HpsVIP.h"
#include <iostream>
#include <filesystem> 

const char* class_names[10] = {
    "apple", "clock", "star", "bicycle", "cookie",
    "moon", "sword", "tree", "T-shirt", "lightning"
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vbnn_soc_wrapper* dut = new Vbnn_soc_wrapper;
    VerilatedFstC* tfp = new VerilatedFstC;
    dut->trace(tfp, 99);
    
    // TỰ ĐỘNG TẠO THƯ MỤC SIM VÀ TRỎ FILE FST VÀO ĐÓ
    std::filesystem::create_directory("sim");
    tfp->open("sim/waveform.fst");
    

    // 1. Khởi tạo SDRAM ảo (1MB, Độ trễ 2 clock)
    SdramVIP sdram(0x30000000, 0x100000, 2);
    if (!sdram.load_txt_image("../../software/fpga_test_vectors/test_img_0.txt", 1024)) return -1;

    dut->clk = 0; dut->reset = 1; dut->read_start_i = 0;

    uint64_t sim_time = 0;
    uint32_t clock_cycles = 0;
    bool enable_dump = false; 

    // Hàm callback đóng vai trò tạo xung nhịp
    auto tick = [&]() {
        dut->clk = 1; dut->eval();
        if (enable_dump) tfp->dump(sim_time);
        sim_time++;
        
        dut->clk = 0; dut->eval();
        
        // Gọi RAM đánh giá tín hiệu
        sdram.eval(
            dut->avm_m0_read, dut->avm_m0_address, dut->avm_m0_burstcount,
            dut->avm_m0_waitrequest, dut->avm_m0_readdatavalid, dut->avm_m0_readdata
        );
        
        if (enable_dump) tfp->dump(sim_time);
        sim_time++;
        clock_cycles++; 
    };

    std::cout << "\n=== HW/SW CO-SIMULATION STARTED ===\n";

    // Reset 20 nhịp
    for (int i=0; i<20; i++) tick();
    dut->reset = 0;
    for (int i=0; i<20; i++) tick();

    // 2. Gọi HPS VIP bắn Trigger
    HpsVIP::trigger_start(dut->read_start_i, tick);
    
    // XÓA ĐỒNG HỒ TRƯỚC KHI BẮT ĐẦU ĐO INFERENCE
    clock_cycles = 0;
    
    // 3. Gọi HPS VIP chờ kết quả
    // Ngân sách 70k, Thời gian delay Verilog là 67k
    HpsVIP::wait_and_profile(
        dut->ai_result_word_o, tick, 
        70000, 67000, 
        clock_cycles, enable_dump
    );

    for (int i=0; i<20; i++) tick();
    tfp->close();
    delete dut; delete tfp;
    return 0;
}
