#include "Vavalon_sdr.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <memory>
#include <vector>
#include <iomanip> // Để in hex đẹp hơn

// Biến toàn cục đếm số cycle
vluint64_t main_time = 0;

// --- Helper: Hàm chạy 1 xung clock ---
// QUY LUẬT: 
// 1. Posedge (0->1): IP thực hiện logic, cập nhật trạng thái FF.
// 2. Eval & Dump.
// 3. Negedge (1->0): Testbench (Slave) chuẩn bị dữ liệu cho cycle sau.
// 4. Eval & Dump.
void tick(Vavalon_sdr *tb, VerilatedVcdC *tfp, VerilatedContext *context) {
    // --- POS EDGE ---
    tb->clk = 1;
    tb->eval();            // Logic FPGA chạy ở đây
    tfp->dump(context->time());
    context->timeInc(1);
    main_time++;

    // --- NEG EDGE ---
    tb->clk = 0;
    tb->eval();            // Logic tổ hợp ổn định
    tfp->dump(context->time());
    context->timeInc(1);
}

// Hàm giả lập Slave RAM thông minh
void run_transaction_cycle(Vavalon_sdr *tb) {
    // Logic này chạy ở NEG-EDGE (chuẩn bị cho Pos-edge tiếp theo)
    // Giống như always @(posedge clk) của Slave bên kia

    static int burst_remaining = 0;
    static bool in_data_phase = false;
    static std::vector<uint32_t> ram_content;
    static int current_data_idx = 0;

    // 1. Xử lý Reset
    if (tb->reset) {
        burst_remaining = 0;
        in_data_phase = false;
        tb->avm_m0_waitrequest = 0;
        tb->avm_m0_readdatavalid = 0;
        return;
    }

    // 2. Slave Logic
    
    // Mặc định tắt valid (trừ khi bật lại ở dưới)
    tb->avm_m0_readdatavalid = 0;

    // A. Giai đoạn nhận lệnh (Address Phase)
    if (!in_data_phase) {
        if (tb->avm_m0_read) {
            // Giả lập Waitrequest ngẫu nhiên (10% cơ hội bị wait)
            if ((rand() % 10) == 0) {
                tb->avm_m0_waitrequest = 1;
            } else {
                tb->avm_m0_waitrequest = 0;
                
                // Chốt lệnh (Latch Command)
                burst_remaining = tb->avm_m0_burstcount;
                in_data_phase = true;
                current_data_idx = 0;

                // Tạo dữ liệu mẫu: 0xA0, 0xA1, 0xA2...
                ram_content.clear();
                for(int i=0; i<burst_remaining; i++) {
                    ram_content.push_back(0xA0 + i); 
                }
                
                printf("[RAM] READ REQ: Addr=0x%x, Burst=%d\n", tb->avm_m0_address, burst_remaining);
            }
        }
    } 
    // B. Giai đoạn trả dữ liệu (Data Phase)
    else {
        // Tắt waitrequest
        tb->avm_m0_waitrequest = 0;
        
        // Tắt do_read của User (giả lập xung pulse 1 cycle)
        if (tb->do_read) tb->do_read = 0;

        if (burst_remaining > 0) {
            // Giả lập độ trễ ngẫu nhiên (Random Latency)
            // 50% cơ hội trả dữ liệu trong cycle này
            if ((rand() % 2) == 0) {
                tb->avm_m0_readdata = ram_content[current_data_idx];
                tb->avm_m0_readdatavalid = 1;
                
                printf("[RAM] -> Returning Data: 0x%x (Left: %d)\n", tb->avm_m0_readdata, burst_remaining - 1);
                
                current_data_idx++;
                burst_remaining--;
            }
        } else {
            // Hết burst, quay về chờ
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
    tfp->open("sim_burst.vcd");

    printf("--- SIMULATION START ---\n");

    // 1. Reset
    tb->reset = 1;
    tb->clk = 0;
    // Chạy vài cycle reset
    for(int i=0; i<5; i++) {
        run_transaction_cycle(tb.get()); // Cập nhật input
        tick(tb.get(), tfp.get(), context.get());
    }
    tb->reset = 0;

    // 2. Kịch bản test: Đọc Burst Length = 2
    // User Trigger
    tb->do_read = 1;
    tb->burst_length = 2; // Đọc 2 số (0xA0 và 0xA1)
    tb->init_addr = 0x200;

    // Chạy mô phỏng 50 clock cycles
    for(int i=0; i<50; i++) {
        // Quan trọng: Update Input Slave TRƯỚC (ở negedge cũ) hoặc SAU (ở negedge mới)
        // Ở đây ta dùng hàm helper chạy ở NegEdge của cycle trước để chuẩn bị cho cycle này
        
        // Bước 1: Logic Slave tính toán input cho Next Cycle
        run_transaction_cycle(tb.get());

        // Bước 2: Tick Clock (Pos -> Neg)
        tick(tb.get(), tfp.get(), context.get());

        // Bước 3: Kiểm tra Output (ngay sau PosEdge)
        // Nếu DataValid vừa lên 1 ở cycle này, thì Logic FPGA sẽ bắt nó ở PosEdge tới.
        // Tuy nhiên, logic always_ff của bạn cập nhật out_data_1 NGAY TẠI CẠNH LÊN ĐÓ.
        // Nên nếu bạn printf ở đây, bạn sẽ thấy giá trị mới.
        
        if (tb->out_data_1 == 0xA1 || tb->out_data_2 == 0xA0) { // Ví dụ check
             // Debug print nếu cần
        }
    }
    
    // In kết quả cuối cùng
    printf("--- FINAL RESULT ---\n");
    printf("Out1 (Expect 0xA1 - odd idx): 0x%x\n", tb->out_data_1);
    printf("Out2 (Expect 0xA0 - even idx): 0x%x\n", tb->out_data_2);

    tfp->close();
    printf("--- SIMULATION END ---\n");
    return 0;
}
