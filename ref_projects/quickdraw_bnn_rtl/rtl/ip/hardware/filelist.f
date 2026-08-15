// Cấu hình cảnh báo & Waveform
-Wall
-Wno-EOFNEWLINE
-Wno-fatal
--trace-fst
--trace-structs   

// Dịch sang mã nguồn C++ (Thiếu cái này nên nó báo lỗi nè)
--cc

// Tìm kiếm tự động trong thư mục hiện tại
-y .

// Top Module
--top-module bnn_soc_wrapper

// Khai báo file RTL (Ưu tiên file package/constant lên đầu)
fc1_constants.sv
bnn_soc_wrapper.sv

// File Testbench C++
--exe sim_main.cpp
--exe ../VIP/SdramVIP.cpp
--exe ../VIP/HpsVIP.cpp
