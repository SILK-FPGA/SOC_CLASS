# avalon_mm_interface 
Đây là giải thích của giao diện avalon memory-mapped. Giao điện này sử dụng phương thức **truyền dữ liệu theo địa chỉ** nha.
<img width="598" height="745" alt="image" src="https://github.com/user-attachments/assets/4171649d-ed9c-4add-81de-b10e926d2e95" />

Hình trên cho ta thấy các thành phần trong hệ thống chia làm 2 vai trò: Host (hay master) và Agent (hay slave). Các khối này đều có giao diện avalon mm bọc bên ngoài để có thể kết nối vào cây cầu interconnect. Nhiệm vụ của cây cầu là định tuyến theo địa chỉ, chuyển đổi từ axi sang avalon (và ngược lại), phân xử theo ưu tiên (arbiter) và mismatch độ rộng bit.

