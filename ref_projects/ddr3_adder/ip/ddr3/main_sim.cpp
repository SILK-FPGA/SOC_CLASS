#include "Vavalon_sdr.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <memory>
#include <vector>

// --- BIẾN TOÀN CỤC ---
vluint64_t main_time = 0;

// --- HÀM TICK (QUAN TRỌNG NHẤT) ---
// Thay đổi chiến thuật: Tách biệt rõ ràng 2 pha
void tick(Vavalon_sdr *tb, VerilatedVcdC *tfp, VerilatedContext *context) {
    // 1. PHASE POS-EDGE (DUT HOẠT ĐỘNG)
    // Tại đây, DUT sẽ lấy các input đã được Testbench chuẩn bị từ CẠNH XUỐNG trước đó.
    tb->clk = 1;
    tb->eval();             // DUT cập nhật trạng thái FF
    tfp->dump(context->time()); // Ghi lại dạng sóng
    context->timeInc(1);
    main_time++;

    // 2. PHASE NEG-EDGE (TESTBENCH CHUẨN BỊ INPUT MỚI)
    tb->clk = 0;
    tb->eval();             // Ổn định logic tổ hợp
    
    // Lưu ý: Chúng ta chưa dump ngay, để dành việc update input ở hàm main
    // rồi mới dump ở cuối chu kỳ neg-edge.
}

// Hàm giả lập Slave RAM (Chạy ở cạnh xuống)
void drive_ram_slave(Vavalon_sdr *tb) {
    static int burst_remaining = 0;
    static bool in_data_phase = false;
    static std::vector<uint32_t> ram_content;
    static int current_data_idx = 0;

    // Reset logic
    if (tb->reset) {
        burst_remaining = 0;
        in_data_phase = false;
        tb->avm_m0_readdatavalid = 0; 
        tb->avm_m0_waitrequest = 0;
        return;
    }

    // --- LOGIC LÁI TÍN HIỆU (Chuẩn bị cho PosEdge TIẾP THEO) ---
    
    // Mặc định tắt valid (trừ khi bật lại ở dưới)
    tb->avm_m0_readdatavalid = 0;

    // A. Address Phase
    if (!in_data_phase) {
        if (tb->avm_m0_read) {
            // Giả lập RAM luôn sẵn sàng (Waitrequest = 0)
            tb->avm_m0_waitrequest = 0;
            
            // Latch lệnh
            burst_remaining = tb->avm_m0_burstcount;
            in_data_phase = true;
            current_data_idx = 0;

            // Tạo data mẫu
            ram_content.clear();
            for(int i=0; i<burst_remaining; i++) ram_content.push_back(0xA0 + i);
            
            printf("[Time %ld] RAM: Nhận lệnh đọc Addr=0x%x, Burst=%d\n", main_time, tb->avm_m0_address, burst_remaining);
        }
    } 
    // B. Data Phase
    else {
        tb->avm_m0_waitrequest = 0;
        
        // Tắt tín hiệu trigger của user (nếu còn)
        if (tb->do_read) tb->do_read = 0;

        if (burst_remaining > 0) {
            // Cấp dữ liệu vào bus
            tb->avm_m0_readdata = ram_content[current_data_idx];
            tb->avm_m0_readdatavalid = 1; // Bật Valid lên
            
            // In ra debug: Lưu ý đây là thời điểm NEG-EDGE
            // DUT sẽ chưa thấy ngay, mà phải đợi PosEdge tiếp theo.
            printf("[Time %ld] RAM: Đẩy Data 0x%x lên bus (Valid=1)\n", main_time, tb->avm_m0_readdata);
            
            current_data_idx++;
            burst_remaining--;
        } else {
            in_data_phase = false;
        }
    }
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    auto tb = std::make_unique<Vavalon_sdr>();
    auto context = std::make_unique<VerilatedContext>();
    auto tfp = std::make_unique<VerilatedVcdC>();

    tb->trace(tfp.get(), 99);
    tfp->open("sim_burst_fixed.vcd");

    printf("--- START SIMULATION ---\n");

    // 1. Reset
    tb->reset = 1;
    for(int i=0; i<5; i++) {
        tick(tb.get(), tfp.get(), context.get());
        tfp->dump(context->time()); // Dump phần NegEdge
        context->timeInc(1);
    }
    tb->reset = 0;

    // 2. Setup Test
    // Chúng ta lái tín hiệu User Trigger tại NegEdge để DUT bắt ở PosEdge sau
    tb->do_read = 1;
    tb->burst_length = 2; 
    tb->init_addr = 0x200;

    // 3. Vòng lặp mô phỏng chính
    for(int cycle=0; cycle<20; cycle++) {
        
        // --- BƯỚC 1: POS EDGE (DUT chạy) ---
        // Tại đây DUT sẽ cập nhật out_data dựa trên input cũ
        tick(tb.get(), tfp.get(), context.get());
        
        // Kiểm tra kết quả ngay sau khi DUT cập nhật (PosEdge)
        if (tb->out_data_1 != 0 || tb->out_data_2 != 0) {
           // Bạn sẽ thấy dòng này in ra TRỄ HƠN so với dòng "RAM: Đẩy Data" 1 chu kỳ
           // printf("[Time %ld] FPGA Output Updated: Out1=0x%x, Out2=0x%x\n", main_time, tb->out_data_1, tb->out_data_2);
        }

        // --- BƯỚC 2: NEG EDGE (Testbench chạy) ---
        // Tính toán input mới cho chu kỳ sau
        drive_ram_slave(tb.get());
        
        // Dump waveform cho phần NegEdge
        tfp->dump(context->time());
        context->timeInc(1);
    }

    printf("--- FINAL RESULT ---\n");
    printf("Out1: 0x%x (Expect 0xA1)\n", tb->out_data_1);
    printf("Out2: 0x%x (Expect 0xA0)\n", tb->out_data_2);

    tfp->close();
    return 0;
}
