# CÁCH CẤU HÌNH THEO DỰ ÁN VỚI QUESTASIM VÀ CHẠY MAKEFILE
## CẤU HÌNH THEO DỰ ÁN

Bên trong thư mục make-file-for-questasim như hình dưới đây, vai trò của các file như sau:
- File config.mk: chứa các cấu hình tùy thuộc theo dự án, phải sửa lại mỗi lần chạy dự án mới.
- File Makefile: file thực thi của Make (một thư viện hỗ trợ tự động hóa phải tải về trên máy trước), giúp tự động toàn bộ quy trình.
- File Questa_license_guide.docx: hướng dẫn cài đặt Questa (hệ điều hành linux hoặc WSL).
- File readme.txt: bạn nào gặp lỗi khi cài do địa chỉ MAC bị đặt lại, xem file này.
- File transcript: Nếu có lỗi xảy ra, xem transcript.

<img width="1283" height="874" alt="image" src="https://github.com/user-attachments/assets/1a73546b-8873-40f8-9cd8-cb966691156b" />

**BƯỚC 1** Mở file config.mk và định nghĩa lại đường dẫn (tới thư mục chứa cả rtl/, tb/, sim/ được tạo ra từ make init), tên top module và tên testbench cần test.

<img width="1312" height="874" alt="image" src="https://github.com/user-attachments/assets/e418cacb-3d44-4ada-81c3-df9f3a866425" />

Makefile là một file đặc biệt, chỉ có thể thực thi lệnh make <lệnh thực thi> khi có sự tồn tại của Makefile tại vị trí gọi lệnh. Có 2 cách để chạy Make:

- Cách 1:Đứng tại thư mục make-file-for-questasim (nơi chứa Makefile) và gọi make, sửa lại đường dẫn bên trong config.mk ở thư mục make-file-for-questasim để Make từ tìm thấy đường tới thư mục.
- Cách 2: Copy Makefile và copy config.mk vào thư mục muốn chạy Make. Rồi chạy make <lệnh thực thi>

**BƯỚC 2** Chạy các lệnh theo thứ tự sau trên wsl hoặc linux terminal hoặc command line window:
```
cd make-file-for-questasim // lệnh nhảy tới thư mục
make help // để tra cứu các lệnh thực thi được và cú pháp
make init // khởi tạo 4 thư mục con bên trong thư mục dự án hiện tại là : rtl/ tb/ sim/ tc/, định nghĩa trong file compile.f 
make all //chạy biên dịch và in ra màn hinh kết quả
make wave // mở cửa sổ sóng
make mem //có thể đóng cửa sổ make wave trước khi mở make mem hoặc chỉ mở make mem, mục đích của lệnh này là soi được các thanh ghi và bộ nhớ bên trong code như fifo, mảng 2d, ...
```
## CCHẠY DỰ ÁN MẪU
Các bước phía dưới sẽ chạy thử với dự án **BNN**. Các bạn có thể lên youtube, vào github dưới phần mô tả để clone code về nhé !

**LƯU Ý TRƯỚC KHI CHẠY** : Questasim và terosHDL sẽ báo lỗi khi trong code verilog sử dụng package, do đó ta phải comment đi phần package để test. Phần trọng số thay vì đọc từ package thì đọc 
trực tiếp từ file .txt luôn nha.

### BNN QUICKDRAW

1. Sửa lại đường dẫn dự án trong config.mk

<img width="1431" height="980" alt="image" src="https://github.com/user-attachments/assets/2d225e22-c06c-4e51-978e-ea6e4e668443" />


2. Sửa lại file top module và comment phần có import package đi để terosHDL và questa ko báo lỗi, khi chạy biên dịch quartus phải thêm lại dòng này vào nhé:

<img width="1331" height="906" alt="image" src="https://github.com/user-attachments/assets/b889a4a5-a189-4560-ac18-9dd685ce5d96" />

3. Chọn module phù hợp để test, phần package mục đích là để nạp trọng số cho fc1_folded_top khi biên dịch, nhưng ở đây ta dùng fc1_folded_top_test để lấy trực tiếp qua file

<img width="1438" height="983" alt="image" src="https://github.com/user-attachments/assets/9737f432-92fc-415f-8aa6-d772fc0975bd" />

4. Chạy tổ hợp lệnh ở trên (bỏ qua make init nếu đã tạo rồi):

 **make init** : lệnh này tạo cây thư mục và file compile.f (file này có thể chỉnh sửa để chọn đúng các khối cần biên dịch với make build và make all)

  <img width="1431" height="980" alt="image" src="https://github.com/user-attachments/assets/b21ef201-39fc-4a95-a572-6386c9e70387" />

**sửa file compile.f**: file này có thể gom rất nhiều testbench (nếu trong thư mục tb/ có nhiều file tb) vào trong lúc biên dịch, nên ta sẽ giữ lại đúng file cần biên dịch mà thôi. Ở đây ta
cần test bdscnn_top nên chọn tb_bdscnn_top.sv

<img width="1431" height="980" alt="image" src="https://github.com/user-attachments/assets/3bac2cdd-2480-4f54-b2f2-e711c1ff8fd9" />


**make all**: lệnh này chạy make build (check lỗi syntax) và make run (chạy mô phỏng không mở cửa sổ sóng, chỉ in ra màn hình)

<img width="1431" height="980" alt="image" src="https://github.com/user-attachments/assets/48e1fcf7-967c-47eb-901b-03ba6de058b2" />

**make wave**: mở cửa sổ sóng để xem 

Cửa sổ hiện ra

<img width="1855" height="1023" alt="image" src="https://github.com/user-attachments/assets/be38ccce-0a57-4f18-9ea3-104676c4894c" />

Bấm chữ 'f' trên màn hình để thu tỉ lệ fit với cửa sổ:

<img width="1855" height="1023" alt="image" src="https://github.com/user-attachments/assets/73c7a0e5-919f-41f4-9586-bd47bf3f2d46" />

Chọn dock/undock, undock cửa sổ waveform hiện tại để thu gọn trong vừa vặn trong khung 

<img width="1452" height="838" alt="image" src="https://github.com/user-attachments/assets/98e2e2b1-dd75-425b-9f5f-146f044d9ddf" />

Sau khi undock, cửa sổ WLF sẽ không nằm rieeng lẻ mà sẽ gom vào trong cửa sổ công cụ như hình dưới:

<img width="1854" height="1050" alt="image" src="https://github.com/user-attachments/assets/cfd67653-53d7-4f0b-a5af-c419ce0e8f7c" />
