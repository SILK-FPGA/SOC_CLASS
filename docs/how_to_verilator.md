# CÁCH TẢI VERILATOR

Verilator là trình mô phỏng SystemVerilog mã nguồn mở, kiểm tra lỗi và biên dịch code RTL file .sv thanh file C++ .cpp để mô phỏng giữa phần cứng và phần mềm.

Tải thông qua ubuntu terminal hoặc WSL trên window với các lệnh như sau để build source :

```
# 1. Cài các gói phụ thuộc cần thiết
sudo apt update
sudo apt install -y git help2man perl python3 make autoconf g++ flex bison ccache
sudo apt install -y libgoogle-perftools-dev numactl perl-doc
sudo apt install -y zlib1g-dev

# 2. Clone repo Verilator
git clone https://github.com/verilator/verilator
cd verilator

# 3. Chọn nhánh/phiên bản ổn định mới nhất (hoặc để mặc định master)
unset VERILATOR_ROOT
git checkout stable

# 4. Build và cài đặt
autoconf
./configure
make -j $(nproc)
sudo make install

# 5. Kiểm tra kết quả
verilator --version
```
hoặc tải nhanh với lệnh
```
sudo apt update
sudo apt install verilator
```
# MÔ PHỎNG VỚI VIP (Verification IP)
## Khái niệm
Vậy VIP là gì ? Là một hệ thống mô phỏng phần cứng vật lý mà không cần tương tác với phần cứng thực, mô tả chính xác các chức năng và hành vi phản hồi của phần cứng thật, một VIP thường có đủ 4 chức năng
cốt lõi sau:
- Master / Driver: Chủ động tạo ra các luồng dữ liệu, gói tin hợp lệ hoặc cố tình tạo các kịch bản lỗi (corner cases, protocol violation) để ép DUT xử lý.

- Slave / Responder: Đóng vai trò phản hồi yêu cầu từ DUT theo đúng đặc tả thời gian (timing/latency) của chuẩn giao thức (ví dụ như lớp SdramVIP của bạn).

- Monitor & Scoreboard: Lắng nghe thụ động các tín hiệu trên bus, thu thập dữ liệu vào/ra để so sánh và chấm điểm tính đúng đắn tự động.

- Assertion & Coverage Checker: Tự động phát hiện các vi phạm quy chuẩn giao thức (như drop dữ liệu, vi phạm setup/hold, timing handshake) và đo lường tỷ lệ các tình huống đã được kiểm thử (functional coverage).
## Các phương pháp triển khai VIP trong công nghiệp
1. SystemVerilog kết hợp Chuẩn UVM (Lựa chọn chủ đạo trong công nghiệp ASIC/FPGA lớn)
  - Công cụ / Simulator: Synopsys VCS, Siemens Questa/ModelSim, Cadence Xcelium.
  - Cách thức: Các kỹ sư DV (Design Verification) sử dụng chuẩn UVM (Universal Verification Methodology) viết hoàn toàn bằng SystemVerilog hướng đối tượng (OOP).
  - Nguồn VIP: Các công ty lớn thường mua trực tiếp các bộ VIP thương mại từ Synopsys hoặc Cadence. Các VIP này đã được chuẩn hóa, cực kỳ phức tạp và hỗ trợ gần như mọi kịch bản lỗi khó nhất của giao thức.
  - Ưu điểm: Khả năng sinh dữ liệu ngẫu nhiên có ràng buộc (Constrained-Random Verification - CRV) cực mạnh và đo lường độ bao phủ (Coverage-Driven Verification - CDV) rất chuẩn xác.
2. C++ / SystemC Co-Simulation kết hợp DPI-C (Xu hướng tối ưu cho AI & SoC phức tạp)
  - Công cụ / Simulator: Verilator, Synopsys Platform Architect, QEMU kết hợp ModelSim/Questa qua DPI-C (Direct Programming Interface), BFM có sẵn từ công cụ Qsys.
  - Cách thức: Sử dụng C++ hoặc SystemC để viết VIP giả lập bộ nhớ, CPU (như HPS), bus interconnect hoặc các mô hình toán học (Golden Model) giống cách của SdramVIP và HpsVIP bên dưới.
  - Sử dụng Verilator để biên dịch toàn bộ RTL sang C++, cho phép chạy mô phỏng với tốc độ nhanh gấp hàng chục đến hàng trăm lần so với trình mô phỏng Event-driven truyền thống.
  - Ưu điểm: Cực kỳ tối ưu cho các dự án tăng tốc phần cứng (AI Accelerators, DSP, Video Processing), nơi testbench cần nạp hàng triệu pixel/trọng số từ file ảnh thực tế và cần tốc độ chạy nhanh để
    đo cycle accuracy (chu kỳ thực thi của mô hình AI).

## Mô phỏng RAM ảo với SDRAM VIP 

- Trước khi tương tác với SDRAM thật, ta cần viết một trình mô phỏng RAM ảo bằng code cpp để tương tác với master IP của người dùng. Ta không cần phải mô phỏng SDRAM ở cấp độ vật lí, mà chỉ cần mô phỏng ở cấp độ giao dịch dữ liệu qua Avalon MM Burst Interface là được. 

- SDRAM ảo cần có những đặc điểm sau:
  - Dữ liệu đẩy ra ở cạnh xuống của clock, để dữ liệu ổn định và Master lấy mẫu ở cạnh lên tiếp theo.
  - Chỉ chấp nhận yêu cầu đọc từ Master khi không thực hiện giao dịch hay đang ở trong chu kì burst nào (burstcount = 0). Handshake xảy ra khi read = 1 và wait_request = 0.
  - Sau khi handshake dữ liệu phải mất một khoảng chu kỳ bằng với độ trễ phản hồi đọc CAS latentcy (CAS Latency = 2 định nghĩa trong SdranVIP.h) làm cho việc đẩy dữ liệu ra chân readdata và cờ      báo datavalid bị trễ đi 2 chu kỳ.
- Đoạn code **SdramVIP.h** vầ **SdramVIP.cpp** nằm trong thư mục dự án quickdraw_bnn_rtl/rtl/ip/hardware trong git này.

## Mô phỏng HPS ảo với HPS VIP
- Chỉ mô phỏng CPU ở cấp độ giao dịch, ghi tín hiệu trigger DMA, polling chờ kết quả từ AI trả về, in ra màn hình kết quả, đặc điểm như sau:
  - Phát tín hiệu trigger:CPU điều khiển IP phần cứng thông qua việc ghi vào các thanh ghi địa chỉ hoặc kéo các chân PIO. HPS VIP phải mô phỏng chính xác hành vi này
  - Polling: Hỏi vòng liên tục cờ báo của khối phần cứng (valid = 1) để đọc dữ liệu từ AI CSR và kết quả dự đoán trả về thông qua PIO_IN. Khả năng sleep và chờ cờ ngắt IRQ từ IP.
  - Đảm bảo setup time và hold time khi tín hiệu đi từ miền logic của HPS sang miền logic của FPGA.
  - Bật dump sóng để quay lại các trạng thái của hệ thống ra waveform.

## Vai trò của file MAIN

- sim_main.cpp là file để kết nối toàn bộ luồng của hệ thống, nó gọi ra và kết nối SdramVIP, HpsVIp và DUT lại với nhau. Kích hoạt các kích thích và gọi các hàm đã định nghĩa trước đó trong file .h để mô phỏng, tạo thư mục sim/waveform.fst để dump dạng sóng, sử dụng systemfile để truy cập file như ảnh test_img_0.txt và cuối cùng là file để thực thi chính của verilator. Mỗi dự
án ta có thể sử dụng chung SdramVIP và HpsVIP nhưng phải tinh chỉnh lại sim_main để tùy theo các kịch bản kiểm thử.

# KHI NÀO THÌ TEST VỚI QUESTA SIM ? KHI NÀO THÌ TEST VỚI VERILATOR ?

Luôn nhớ một nguyên tắc rằng: unit test thì questa, system test thì verilator. Khi mình muốn test chức năng của từng khối riêng lẻ, thì khối đó phải đúng chức năng theo từng chu kì, việc này khi
mô phỏng questasim với số chu kì và clock nhỏ (dưới 50MHz hoặc dưới 1 triệu chu kì clock) sẽ giúp bắt được các lỗi chính xác hơn. Khi thời gian mô phỏng tăng lên, và cần test thử code phần mềm như C++, ta phải chạy verilator để kiểm tra hệ thống. Đồng thời ta có thể kiểm tra được tính đúng đắn của code C++ trước khi chạy hệ thống thực.

Tuyệt đối không test các khối IP thuộc vendor sẵn có (nghĩa là các khối chỉ cần kéo ra là sử dụng) vì sẽ phí thời gian, thay vào đó ta mô phỏng các khối này thông qua các hàm của C++ (function).

# VÍ DỤ VỚI QUICKDRAW BNN SOC

## Delay của custom DMA 

Với read_avalon_sdr, nếu trỏ vào RAM quá nhanh để đọc dữ liệu, sẽ gây hiện tượng treo bus axi hoặc trả về dữ liệu sai. Ngay khi khởi động lần đầu tiên, ta thường chờ 1 khoảng để hệ thống ổn định trước khi Master đọc. Ở hình dưới, Master chờ 67 triệu chu kì, clock 50 MHz thì tương ứng với chờ trong khoảng 1.34s. Thời gian này có thể tùy chỉnh tùy theo hoạt động thực tế trên phần cứng. Cách làm này là cách làm best practice khi tương tác với RAM ! Như hình dưới:

<img width="1195" height="783" alt="image" src="https://github.com/user-attachments/assets/2c5b1317-c265-4333-84d4-7a824b10cc36" />

Nếu test khối này với Questasim, ta chỉ cần test để đảm bảo chức năng của Master read hoạt động chính xác, tuy nhiên rằng ta phải viết mô phỏng RAM bằng System Verilog, đây là việc rất phức tạp.

Do đó, khi unit test các khối có Avalon Master Interface (giao dịch avalon kiểu master) hoặc AXI Master Interface (giao dịch axi kiểu master) mà việc mô phỏng Slave quá phức tạp (I2C, SPI, RAM) hoàn toàn có thể dùng verilator.

## Các kết nối của DUT

Nhìn vào file top DE10_nano.sv, Hệ thống của ta gồm 3 khối cốt lõi cần test: bdscnn_top (chứa lõi AI), buffer AI (đóng gói ảnh dạng song song và truyền vào nối tiếp), ai_result_register (các trạng thái của bdscnn_top), ta đóng gói vào module DUT (design under test) có tên là **bnn_soc_wrapper** để test với verilator. Sơ đồ của DUT và môi trường của nó như sau:

<img width="1668" height="768" alt="image" src="https://github.com/user-attachments/assets/597249e0-6107-45ad-90ad-bae2f2fd0363" />

Vai trò của các khối: như đã mô tả ở phần SDRAM VIP và HPS VIP ở trên. Riêng DUT, ta cần phải có các chân interface để tương tác với các VIP như hình dưới:

<img width="1269" height="796" alt="image" src="https://github.com/user-attachments/assets/7e7fa20d-406b-472c-aacf-e2099616abdf" />

## Phân tích hoạt động của hệ thống

sim_main.cpp sẽ điều phối toàn bộ chức năng và luồng dữ liệu, thay vì mô phỏng với 67000000 clock, ta giảm thời gian chờ bên trong của read_avalon_sdr xuống 67000 clock để tăng tốc độ mô phỏng, xem các chú thích code bên dưới đây:
```
// CÁC FILE HEADER ĐỊNH NGHĨA HÀM 
#include "Vbnn_soc_wrapper.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "SdramVIP.h"
#include "HpsVIP.h"
#include <iostream>
#include <filesystem> 

//
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
    
    // TỰ ĐỘNG TẠO THƯ MỤC SIM VÀ CHUYỂN WAVEFORM VÀO ĐÓ
    std::filesystem::create_directory("sim");
    tfp->open("sim/waveform.fst");
    
    // GỌI VÀ CẤU HÌNH VIP 
    // 1. Khởi tạo SDRAM ảo (1MB, Độ trễ 2 clock)
    SdramVIP sdram(0x30000000, 0x100000, 2); // có thể chỉnh tùy theo hoạt động thực tế
    if (!sdram.load_txt_image("../../software/fpga_test_vectors/test_img_0.txt", 1024)) return -1; // thay đổi ảnh cần test

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
        
        // CÁC LỆNH TƯƠNG TÁC VỚI MASTER CỦA RAM 
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
    // Tạo thời gian chờ tối đa 70k, Trừ đi Thời gian delay để ổn định RAM và phần cứng là 67k, vậy kể từ khi lệnh đọc xảy ra, ai_result_word phải hợp lệ trong khoảng thời gian 3k chu kì.
    // Thực tế thì lõi AI tính toán xong trong 1035 chu kì, nếu con số này vượt quá 3k, hệ thống sẽ trả ra không phản hồi !
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
```

 


