# QUARTUS VÀ CÁCH CẤU HÌNH CHI TIẾT CHO CÁC DỰ ÁN FPGA
## MỞ DỰ ÁN KHI TẢI VỀ TỪ GITHUB
Giao diện khi vừa mở quartus lite lên như hình dưới đây. Các bạn chọn **Open Project** để mở dự án có sẵn. File dự án sẽ có dạng **du_an.qpf**. Khi chọn project cần mở các bạn chỉ có thể chọn các file 
có định dạng này:

Giao diện

<img width="1311" height="740" alt="image" src="https://github.com/user-attachments/assets/ce703286-22c5-433a-81c3-aece13c278e6" />

Chọn dự án **DE10_NANO_SoC_GHRD.qpf** để mở.

<img width="1472" height="888" alt="image" src="https://github.com/user-attachments/assets/d7dee52d-96c4-4ea9-a84f-00d8dc155153" />

Sau khi mở dự án lên, ta cần nắm những vị trí cơ bản của công cụ Quartus được đánh số như hình dưới

<img width="1828" height="852" alt="image" src="https://github.com/user-attachments/assets/579a44ce-8f5a-4945-be00-3d09f9a73497" />

- 1. Mã chip của FPGA, ở đây ta đang sử dụng fpga DE10 Nano, chip CYCLONE V SoC có mã: 5CSEBA6U23I7. Lưu ý chọn đúng mã, nếu không biên dịch xong sẽ không chạy được.
     
- 2. Tên module top của hệ thống. Module này sẽ nối ra ngoài các chân I/O trên chip. Module này cũng gọi các module con nhỏ hơn và kết nối mọi thứ lại với nhau. Click đúp chuột phải vào để xem nội dung file top "DE10_NANO_SoC_GHRD.v" như hình dưới

    <img width="1165" height="875" alt="image" src="https://github.com/user-attachments/assets/53ff9cca-1d74-43da-9027-355d4118c078" />

  
- 3. Chế độ xem: Hierachy, xem cấu trúc cây module, vị trí của các module từ top module tới các module con nhỏ hơn của dự án. Bấm vào dấu mũi tên sổ xuống bên cạnh module top **DE10_NANO_SoC_GHRD**
để xem các module bên dưới nó.

  <img width="684" height="587" alt="image" src="https://github.com/user-attachments/assets/aed9a018-19fe-4f69-add6-a7e8d53926fc" />

  Chế độ xem còn có thể chuyển sang Files, để xem các tệp sử dụng cho dự án như ".v" ".sv" ".qip". Kiểm tra đã thêm đủ các các file RTL vào đây chưa nhé.

  <img width="886" height="732" alt="image" src="https://github.com/user-attachments/assets/fb83e9b8-4e99-4af8-b039-96d7f23a80fd" />

  
