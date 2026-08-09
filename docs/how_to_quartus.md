# QUARTUS VÀ CÁCH CẤU HÌNH CHI TIẾT CHO CÁC DỰ ÁN FPGA
## MỞ DỰ ÁN KHI TẢI VỀ TỪ GITHUB
Giao diện khi vừa mở quartus lite lên như hình dưới đây. Các bạn chọn **Open Project** để mở dự án có sẵn. File dự án sẽ có dạng **du_an.qpf**. Khi chọn project cần mở các bạn chỉ có thể chọn các file 
có định dạng này:

Giao diện

<img width="1311" height="740" alt="image" src="https://github.com/user-attachments/assets/ce703286-22c5-433a-81c3-aece13c278e6" />

Chọn dự án **DE10_NANO_SoC_GHRD.qpf** để mở.

<img width="1472" height="888" alt="image" src="https://github.com/user-attachments/assets/d7dee52d-96c4-4ea9-a84f-00d8dc155153" />

Sau khi mở dự án lên, ta cần nắm những vị trí cơ bản của công cụ Quartus được đánh số như hình dưới

<img width="1847" height="859" alt="image" src="https://github.com/user-attachments/assets/0c584c21-5117-49b4-9113-1aae5298a300" />


1. Mã chip của FPGA, ở đây ta đang sử dụng fpga DE10 Nano, chip CYCLONE V SoC có mã: 5CSEBA6U23I7. Lưu ý chọn đúng mã, nếu không biên dịch xong sẽ không chạy được.
     
2. Tên module top của hệ thống. Module này sẽ nối ra ngoài các chân I/O trên chip. Module này cũng gọi các module con nhỏ hơn và kết nối mọi thứ lại với nhau. Click đúp chuột phải vào để xem nội dung file top "DE10_NANO_SoC_GHRD.v" như hình dưới

    <img width="1165" height="875" alt="image" src="https://github.com/user-attachments/assets/53ff9cca-1d74-43da-9027-355d4118c078" />

3. Chế độ xem Hierachy: xem cấu trúc cây module, vị trí của các module từ top module tới các module con nhỏ hơn của dự án. Bấm vào dấu mũi tên màu đen sổ xuống bên cạnh module top **DE10_NANO_SoC_GHRD**
để xem các module bên dưới nó.

  <img width="684" height="587" alt="image" src="https://github.com/user-attachments/assets/aed9a018-19fe-4f69-add6-a7e8d53926fc" />

   Chế độ xem còn có thể chuyển sang chế độ Files, để xem các tệp sử dụng cho dự án như ".v" ".sv" ".qip". Kiểm tra đã thêm đủ các các file RTL vào đây chưa nhé.

  <img width="886" height="732" alt="image" src="https://github.com/user-attachments/assets/fb83e9b8-4e99-4af8-b039-96d7f23a80fd" />

4. Cửa sổ thông báo: khi chạy biên dịch và tổng hợp, errors (lỗi) và warning (cảnh báo) sẽ xuất hiện ở cửa sổ này, có thể kéo giãn kích thước cửa sổ để xem rõ hơn.
   
5. Thanh trạng thái thể hiện các bước thực thi của hệ thống: Compile Design, Fitter, PnR,..., trong quá trình chạy thực thi nếu thành công thì sẽ hiện dấu tích màu xanh bên cạnh tên bước. Nếu không thành công sẽ hiện dấu chéo màu đỏ. Khi đó ta cần kiểm tra các lỗi và cảnh báo tại cửa sổ thông báo.

6. Sau khi chọn chế độ xem Files, ta click đúp vào 1 file để xem và chỉnh sửa tại cửa sổ này, ví dụ: bdscnn_top.sv. Nếu thực hiện chỉnh sửa nhưng chưa lưu thay đổi với Ctrl + S, sẽ xuất hiện dấu * cạnh tên file "bdscnn_top.sv*", khi lưu thay đổi dấu * sẽ biến mất.

<img width="1854" height="859" alt="image" src="https://github.com/user-attachments/assets/68ace80b-4bed-4b87-9315-f72669816b73" />

7. Các nút thực thi hệ thống: từ trái sang có các biểu tượng: STOP (dừng khi đang biên dịch), tam giác màu xanh (chạy toàn bộ các bước tới bitstream), tam giác màu xanh có dấu tick màu xanh (check lỗi và chạy tới bước gán các chân I/O), tam giác màu xanh có dấu tick màu xanh và hình vuông (check lỗi và chạy tới bước tổng hợp ra netlist RTL).

8. Thanh tác vụ để điều khiển công cụ.

## CÁC FILE CẤU HÌNH:

File cấu hình dự án có thể điều chỉnh mỗi khi có thay đổi, ở đây chỉ liệt kê và giới thiệu các file chính gồm: Quartus Project File (.qpf), Quartus Setting File (.qsf), Synopsys Design
Constraint (.sdc):

<img width="1332" height="729" alt="image" src="https://github.com/user-attachments/assets/03847cb8-567d-4d93-8e4d-26b37f9924c5" />

- .qpf (Quartus Prime Project File)

     - Bản chất: Tệp định danh dự án cấp cao nhất.

     - Nhiệm vụ: Chứa thông tin phiên bản Quartus đã tạo dự án và trỏ tới tệp cấu hình chính (.qsf). Tệp này rất ngắn, thường chỉ gồm vài dòng text. Phiên bản quartus có thể cũ vì tool sẽ tự cấu hình         theo phiên bản Quartus hiện tại.


<img width="1332" height="729" alt="image" src="https://github.com/user-attachments/assets/a70243a3-edef-4e67-ba8a-5aba1c8c663c" />

- .qsf (Quartus Settings File)

     - Bản chất: Tệp chứa toàn bộ thiết lập của dự án. File này sẽ do Quartus tự động tạo ra tương ứng với cấu hình của người dung trên GUI của Quartus. Có thể chỉnh sửa thủ công trong file này để lưu cài đặt mà không cần mở GUI. 
     
     - Nhiệm vụ:
     
          - Khai báo dòng chip/mã chip FPGA target (ví dụ: set_global_assignment -name DEVICE 5CSEBA6U23I7).
          
          - Gán chân I/O với các chuẩn điện áp, drive strength (set_location_assignment PIN_U10 -to HDMI_I2C_SCL), gán I/O của top với pin I/O vật lý trên chip (set_location_assignment PIN_AH17 -to KEY[0]).
          
          - Danh sách toàn bộ các file nguồn RTL (.v, .sv, .vhd, .ip). Tên của top module (set_global_assignment -name TOP_LEVEL_ENTITY "DE10_NANO_SoC_GHRD")
          
          - Các tùy chọn biên dịch (Synthesis/Fitter Settings).

<img width="1855" height="963" alt="image" src="https://github.com/user-attachments/assets/16f34d74-072b-4b24-9513-828ad73d607d" />


- .sdc (Synopsys Design Constraints File)
  - Bản chất: Tệp ràng buộc thời gian (Timing Constraints) theo chuẩn Synopsys.

     - Nhiệm vụ: Cung cấp thông tin cho công cụ TimeQuest Timing Analyzer để thực hiện STA (Static Timing Analysis).

          - Nội dung chính:
          
          - Khai báo clock đầu vào: create_clock -period 10.000 -name clk [get_ports {clk}]
          
          - Khai báo Generated Clock (ví dụ output của PLL).
          
          - Thiết lập thời gian Input/Output Delay (set_input_delay, set_output_delay).
          
          - Ràng buộc bất đồng bộ (False Path, Multicycle Path): set_clock_groups -asynchronous ...
          
          - Lưu ý thực tế: Nếu thiết kế bộ tăng tốc phần cứng chạy ở tần số cao, thiếu tệp .sdc sẽ khiến Fitter tối ưu đường chạy không chính xác, dẫn đến lỗi timing thực tế trên phần cứng dù mô phỏng             functional chạy đúng. File này phải do người dùng viết, tool không tự tạo ra.
          - 
<img width="1855" height="963" alt="image" src="https://github.com/user-attachments/assets/92d8c9cd-cd29-4412-9ec2-b264a450dc0b" />

