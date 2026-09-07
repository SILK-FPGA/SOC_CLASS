# Mục tiêu

Sau khi xem toàn bộ nội dung bên dưới, các bạn có thể nắm được:
- Tự build một hệ điều hành linux nhúng tùy chỉnh (custom embedded linux image).
- Tự biết cần phải làm gì khi mới mua board SoC của Altera, hoặc mới tiếp xúc lần đầu với các board SoC khác.
- Sử dụng Qsys (cái này đã chỉ xuyên suốt trong khóa học).
- Tự tạo IP tùy chỉnh và code cho userspace (cái này đã chỉ xuyên suốt khóa học).

Toàn bộ nội dung được cập nhật mới nhất cho tới tháng 9/2026, hệ điều hành debian linux, nên những bạn nào sử dụng hệ điều hành Window thì có thể khác đôi chút. Hướng dẫn dựa trên kinh
nghiệm cá nhân, nếu không chạy được ở bước nào thì các bạn liên hệ lại trong khóa học nhé.

# Bước 1: Chuẩn bị

Các bạn mới tiếp xúc Altera SoC FPGA lần đầu hay mới mua board về, cần làm đầu tiên là các bạn hãy lên trang của nhà sản xuất. Cài các property của board đi kèm, thường là trang chủ của 
nhà cung cấp trong mục resources [De10-nano](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=4#contents). Kéo xuống dưới, tới khi thấy 
mục như hình dưới. Bấm tải về DE10-Nano CD-ROM của board (chứa hướng dẫn sử dụng, tài liệu, demo..), bản của board phụ thuộc vào mã chip, như của mình thì chọn CD-ROM rev E.

<img width="1842" height="999" alt="image" src="https://github.com/user-attachments/assets/0cac55e8-9bd4-4adc-8cc7-e52dabc4e86c" />

Tiếp tục kéo xuống tải về Linux BSP, đây là các image linux được build sẵn đi kèm. Chỉ cần tải về, chép vào thẻ SD, cắm vào board rồi boot lên là dùng được ngay. Chọn bản Desktop nếu muốn
có giao diện GUI đẹp lên màn hình.

<img width="1842" height="999" alt="image" src="https://github.com/user-attachments/assets/39fc9010-b67b-45fc-b2dd-8161fc0c6b18" />

Ở trong github này, mình hướng dẫn các bạn cách tự build một linux image mà không cần dùng cái có sẵn.

Tiếp theo, ta cần 2 công cụ mà mình đã hướng dẫn cài trong khóa học:
- Quartus Lite (bản 20.1 theo mình là ổn định nhất).
- SoC_EDS.

Khi tải về, toàn bộ sẽ nằm trong thư mục intelFPGA_lite/ 

<img width="1248" height="670" alt="image" src="https://github.com/user-attachments/assets/5d7db4bf-4431-44ac-aca6-aff5add0d06b" />

Nhớ rằng ta phải gạt toàn bộ MSEL (nút gạt) lên mức ON hết toàn bộ.

# Bước 2: Thiết kế custom IP từ GHRD

Terasic, nhà sản xuất bo mạch DE10-Nano, cũng cung cấp các GHRD cho các sản phẩm của họ. DE10-Nano CD-ROM, nơi chứa mọi thứ cần thiết.

Sau khi tải xuống và giải nén tệp zip SystemCD, bạn sẽ thấy một số thiết kế tham khảo (reference designs) trong thư mục *Demonstrations*. 

GHRD mà chúng ta sẽ sử dụng trong hướng dẫn này nằm tại đường dẫn **`Demonstrations/SoC_FPGA/DE10_NANO_SoC_GHRD`**.

Khi đã hoàn tất hướng dẫn này và hệ thống đã hoạt động ổn định, các bạn có thể bắt đầu với các GHRD khác hoặc các thiết kế của khóa học SoC mình đã dạy.

Hình bên dưới là các vị trí file GHRD

<img width="1331" height="519" alt="image" src="https://github.com/user-attachments/assets/518c14a9-adc0-4d07-b361-e9647989df51" />

Nhìn vào bên trong thư mục

<img width="1602" height="524" alt="image" src="https://github.com/user-attachments/assets/2abc9fd7-fe7d-4ab6-8cf5-2314f8121287" />

**Lưu ý**: File GHRD là file đã được tối ưu theo nhà sản xuất, vậy nên nếu sửa đổi, hãy copy file này ra một thư mục riêng, lỡ như có sai thì còn bản gốc để đối chiếu nhe các bạn.

## Chỉnh sửa GHRD

Trong ví dụ mẫu, GHRD gọi ra và kết nối các IP thông dụng nhất trong QSYS như hps_0, mm_bridge, jtag_uart, các chân pio, v.v.. Như hình dưới

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/e740f2bb-d6a2-4fe2-9101-c38ced46221c" />

Ta sẽ loại bỏ khối led_pio, click chuột phải **led_pio**, chọn remove. Ta sẽ tự thiêt kế khối này như đã học.
## Tạo custom IP

Bước này ta đã quá quen thuộc trong quá trình học, tuy nhiên để hướng dẫn đầy đủ và hoàn chỉnh mà cũng sẽ chỉ lại sơ bộ.

Hãy tạo thư mục `custom_leds` tại `DE10_NANO_SoC_GHRD/ip/`, sau đó tạo tệp `custom_leds.sv` bên trong thư mục `DE10_NANO_SoC_GHRD/ip/custom_leds/` vừa tạo. Sao chép và dán đoạn mã sau vào
tệp `custom_leds.sv`
```
module custom_leds
(
    input  logic        clk,                // clock.clk
    input  logic        reset,              // reset.reset
    
    // giao diện avalon mm read/wr 
    input  logic        avs_s0_address,     // avs_s0.address
    input  logic        avs_s0_read,        // avs_s0.read
    input  logic        avs_s0_write,       // avs_s0.write
    output logic [31:0] avs_s0_readdata,    // avs_s0.readdata
    input  logic [31:0] avs_s0_writedata,   // avs_s0.writedata
    
    // led hiên thị
    output logic [7:0]  leds
);

// port read của avalon mm slave
always_comb begin
    if (avs_s0_read) begin
        case (avs_s0_address)
            1'b0    : avs_s0_readdata = {24'b0, leds};
            default : avs_s0_readdata = 'x;
        endcase
    end else begin
        avs_s0_readdata = 'x;
    end
end

// port write của avalon mm slave
always_ff @ (posedge clk) begin
    if (reset) begin
        leds <= '0;
    end else if (avs_s0_write) begin
        case (avs_s0_address)
            1'b0    : leds <= avs_s0_writedata;
            default : leds <= leds;
        endcase
    end
end

endmodule // custom_leds
```
### Thêm vào QSYS custom_led

Đoạn này mình sẽ không hướng dẫn nhiều, vì các bạn đã làm quen và nắm quy trình thêm new_component, chọn interface avalon memory mapped trong QSYS rồi. Kết quả như bên dưới đây sau khi
thêm các interface vào custom_led ip:

<img width="636" height="410" alt="image" src="https://github.com/user-attachments/assets/7c700633-f668-47f2-8cca-7ca8e95132c3" />

Thêm chân conduit, để nối với led ở ngoài FPGA.

<img width="717" height="359" alt="image" src="https://github.com/user-attachments/assets/9c3e039a-a05f-491d-b455-c152df43c952" />

Đảm bảo *Message* không báo bất kì errors nào, lưu lại và bấm Finish, nhớ là mỗi lần chỉnh sửa code RTL '.v,.sv' thì đều phải vào cửa sổ ở trên rồi ấn Analyze Synthesis File và lưu lại
nhé.

Còn một bước cuối cùng để hoàn tất việc tạo thành phần tùy chỉnh của chúng ta. Sau này, khi chuẩn bị cấu hình và biên dịch kernel Linux, chúng ta sẽ tạo ra một Device Tree 
để thông báo cho nhân hệ điều hành biết những loại phần cứng nào đang hiện diện trong hệ thống. Kernel hệ điều hành có thể sử dụng thông tin này, chẳng hạn như để nạp các trình 
điều khiển (driver) tương ứng. Để đảm bảo custom IP được thêm vào Device Tree một cách chính xác, chúng ta cần chỉnh sửa tệp `custom_leds_hw.tcl` – tệp tin được Qsys tạo ra khi 
chúng ta lưu lại các thay đổi vừa thực hiện.
```
# Device tree generation
set_module_assignment embeddedsw.dts.vendor "dsa"
set_module_assignment embeddedsw.dts.compatible "dev,custom-leds"
set_module_assignment embeddedsw.dts.group "leds"
```
### Kết nối custom_led với hệ thống
Để thêm linh custom ip vào thiết kế phần cứng, hãy nhấp đúp vào mục "Custom LEDs" trong phần Project thuộc thẻ IP Catalog,
sau đó nhấp vào nút Finish trên cửa sổ xuất hiện:

<img width="277" height="298" alt="image" src="https://github.com/user-attachments/assets/31c2aca8-e230-4de2-a9ca-c8d22ad23c1a" />

Sau khi đã thêm thành phần tùy chỉnh vào thiết kế phần cứng, chúng ta cần kết nối nó với phần còn lại của hệ thống. Như hình dưới

<img width="1845" height="745" alt="image" src="https://github.com/user-attachments/assets/922e3a05-998a-490b-a99d-03bb07860636" />

Bước cuối cùng là thiết lập kết nối cho cổng ra `leds` . Nhấp chuột phải vào `leds` thuộc instance `custom_leds_0` và chọn **Connections**: `custom_leds_0.leds` → **Export as**: `custom_leds_0_leds`. 
Thao tác này xuất cổng ra `leds` của IP tùy chỉnh thành một external, để có thể truy cập  ở vùng FPGA, vì chúng ta muốn kết nối nó với các đèn LED trên FPGA.

Xong rồi thì ấn **Generate HDL** của QSYS để đóng gọi thành soc_system nhe.

### Chỉnh sửa file top
Vào Trong tệp  tên DE10_NANO_SoC_GHRD.v, tìm `led_pio_external_connection_export` và thay thế nó bằng tín hiệu đã xuất của chúng ta là `custom_leds_0_leds_new_signal`. 
Như vậy, chúng ta chuyển từ trạng thái này

<img width="506" height="78" alt="image" src="https://github.com/user-attachments/assets/e98bcf7e-51fd-444c-a498-7cf4fa8dc252" />

sang trạng thái này

<img width="506" height="78" alt="image" src="https://github.com/user-attachments/assets/cba94d64-edc9-4737-a567-41d2b14204ed" />

Thay đổi cuối cùng chỉ áp dụng với các phiên bản quartus cũ vì Qsys đang khởi tạo thành phần tùy chỉnh của chúng ta không chính xác. 
Thành phần của chúng ta có tên là `custom_leds` nhưng Qsys lại nhận diện nó là `new_component`. Trong Project Navigator, hãy chuyển chế độ hiển thị Hierarchy sang Files 
và mở tệp `soc_system/synthesis/soc_system.v`:

<img width="560" height="301" alt="image" src="https://github.com/user-attachments/assets/25723efc-3d22-49dc-8336-3bd531619c26" />

Tìm 'new_component':

<img width="669" height="168" alt="image" src="https://github.com/user-attachments/assets/22a15f80-d76f-41a5-bb14-95f9a44c546c" />

Sửa lại thành custom_leds:

<img width="662" height="162" alt="image" src="https://github.com/user-attachments/assets/03953666-1cd3-40f7-88b2-29bfd9c87cf5" />

### Tổng hợp và tạo file rbf

Bước này mình đã chỉ ở các bài trước, các bạn cứ làm theo như hình dưới để chuyển đổi file .sof sau khi Synthesis thành file .rbf nhe

<img width="792" height="726" alt="image" src="https://github.com/user-attachments/assets/3aa4a6ff-5812-45f6-b29d-aee5075e7721" />

**Lưu ý** Trong github này mình tải lên thư mục sẵn, nhưng các bạn khi tải về dùng phải upgrade IP nhe.

<img width="1847" height="1048" alt="image" src="https://github.com/user-attachments/assets/e0daafe6-f279-4b28-83f7-57f861ef0b2e" />

