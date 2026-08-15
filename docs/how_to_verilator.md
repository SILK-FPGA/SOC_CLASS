# Cách tải verilator

Verilator là trình mô phỏng SystemVerilog mã nguồn mở, kiểm tra lỗi và biên dịch code RTL file .sv thanh file C++ .cpp để mô phỏng giữa phần cứng và phần mềm.

Tải thông qua ubuntu terminal hoặc WSL trên window với các lệnh như sau:

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
# Mô phỏng với VIP (Verification IP)
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

# Mô phỏng RAM ảo với SDRAM VIP 

Trước khi tương tác với RAM thật, ta cần viết một trình mô phỏng RAM ảo bằng code cpp để tương tác với master IP của người dùng. Ta không cần phải mô phỏng RAM ở cấp độ vật lí, mà chỉ cần mô phỏng ở cấp 
độ giao dịch dữ liệu qua Avalon MM Burst Interface là được. Cách mô phỏng này gọi là mô p

Đoạn code mô tả RAM ảo như sau, trước tiên tạo Sdram_VIP
```


