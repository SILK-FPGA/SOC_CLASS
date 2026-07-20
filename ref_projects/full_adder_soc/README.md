## LAB1: Thiết kế một bộ cộng đơn giản bên miền FPGA, thiết kế giao diện avalon-mm, kết nối với HPS và viết code C điều khiển

<img width="1003" height="448" alt="image" src="https://github.com/user-attachments/assets/7f035819-68e9-4838-9a71-8052c5b2be9b" />

*Các bước tiếp cận* 
1) Đầu tiên, ta cần xác định 3 điểm mấu chốt cần thiết kế: sử dụng cây cầu nào (h2f light weight, h2f heavy weight, f2h, f2sdram), giao thức nào (avalon hay axi) và phương thức nào (memory-mapped hay streaming).
2) Ta cần bọc bên ngoài khối IP mà ta đã viết giao diện avalon. Để có thể kết nối vào interconnect.
3) Sử dụng Plaform designer để kết nối hệ thống. Export các chân ra ngoài nếu cần thiết. 
4) Ánh xạ các slave thành các địa chỉ riêng biệt, không đè lên nhau, và có độ rộng hợp lệ.
5) Kiểm tra trạng thái của linux kernel, kiểm tra device tree, kiểm tra các cây cầu đã enable chưa.
6) Biên dịch hệ thống thành file .rbf, viết code C và kiểm tra hệ thống.
**Cụ thể bài toán**
- Nhìn về phía CPU, dữ liệu ghi vào a và b, dữ liệu đọc từ sum. Do đó đối với CPU, a và b là output, sum là input.
- Khi thiết kế khối pio_in và pio_out, cần lưu ý độ rộng phải hợp lệ (1, 8, 16, 32, 64, 128), nếu độ rộng khác khoảng này cần đệm cho đủ số bit ở vùng không sử dụng.
- PIO64_IN là khối giao diện giúp cho CPU đọc dữ liệu trả về từ sum, nên ta cần 2 chân tín hiệu là readdata, read, dĩ nhiên phải có clk và reset.
- 
  <img width="742" height="558" alt="image" src="https://github.com/user-attachments/assets/d5f1f2d8-4042-4a86-b2e9-bcdc500739c0" />
  
- PIO64_OUT là khối giao diện giúp cho CPU ghi dữ liệu vào a và b, nên ta cần 2 chân tín hiệu là writedata, write, có thể tạo 2 khối độc lập là PIO64_IN1 và PIO64_OUT, để thấy sự thay đổi giá trị ở 2 vùng địa chỉ khác nhau tương ứng cho a và b, khối này phải có clk và reset.
- 
<img width="742" height="558" alt="image" src="https://github.com/user-attachments/assets/08f41740-57b9-4c76-9d9b-f2e6c32b1c71" />

**>>*LƯU Ý*<<** Nếu muốn sử dụng tính năng code analyzer của platform designer, ta có thể tuân thủ theo format (tuy nhiên khuyến khích tùy chỉnh tay ở bước sau đó để đảm bảo chính xác):

  ```avs (Avalon-MM Slave / Agent)

     avm (Avalon-MM Master / Host)

     asi (Avalon-ST Sink / Đầu vào)

     aso (Avalon-ST Source / Đầu ra)

     csi (Clock Sink) - Tuy nhiên, chỉ cần đặt clk là Qsys đã tự hiểu.

     rsi (Reset Sink) - Tương tự, chỉ cần đặt reset hoặc reset_n.

     coe (Conduit Export) - Dùng cho các tín hiệu ngoại vi nối ra ngoài.```
- Trong thiết kế của LAB này, sử dụng cầu h2f heavy weight giao diện axi (h2f_axi_master), cây cầu này có độ rộng được lựa chọn là 64 bit. Như hình dưới.

<img width="1452" height="730" alt="image" src="https://github.com/user-attachments/assets/0d6419a8-4e9c-40f6-b6f9-a473443a14e2" />

**Hoàn toàn có thể chọn cầu lightweight (32 bit) để tương thích với thiết kế, hoặc có thể chỉnh độ rộng của a, b, sum lên 64 bit để tương thích với cầu**
- Khi kết nối cần đảm bảo các chân của clk và reset đều được nối vào, error báo ở góc dưới cùng bên trái phải bằng 0. Các master phải nối vào slave mà nó muốn điều khiển. Như hình dưới.

<img width="1853" height="989" alt="image" src="https://github.com/user-attachments/assets/44da9bfe-53b3-4a5f-b7e4-887a899fede9" />

- Lưu lại với ctrl+S, generate HDL code là xong.

