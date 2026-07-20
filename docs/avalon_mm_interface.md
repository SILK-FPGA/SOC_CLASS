# avalon_mm_interface 
Đây là giải thích của giao diện avalon memory-mapped. Giao điện này sử dụng phương thức **truyền dữ liệu theo địa chỉ** nha.

<img width="598" height="745" alt="image" src="https://github.com/user-attachments/assets/4171649d-ed9c-4add-81de-b10e926d2e95" />

Hình trên cho ta thấy các thành phần trong hệ thống chia làm 2 vai trò: Host (hay Master) và Agent (hay Slave). Các khối này đều có giao diện avalon mm bọc bên ngoài để có thể kết nối vào cây cầu interconnect (như trong ví dụ full adder soc là cây cầu mm_bridge). Nhiệm vụ của cây cầu là định tuyến theo địa chỉ đưa dữ liệu tới các Agent, chuyển đổi từ axi sang avalon (và ngược lại), phân xử theo ưu tiên (arbiter), khớp độ rộng bit khi có sai khác. Khi CPU kết nối và có yêu cầu ghi (write) với dữ liệu ghi (write data), CPU sẽ đóng vai trò như một Host, và cây cầu interconnect lúc này là Agent. Interconnect nhận dữ liệu và lệnh từ CPU, và đóng vai trò một Host để làm việc với các Agent khác trong hệ thống (các IP có sẵn khác, hoặc IP do mình viết). 

