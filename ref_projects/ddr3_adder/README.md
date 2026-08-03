# HƯỚNG DẪN CHI TIẾT DỰ ÁN DDR3_ADDER TƯƠNG TÁC VỚI RAM THÔNG QUA CUSTOM DMA 

## Các vùng nhớ trên SDRAM
SDRAM là thành phần bộ nhớ đặc biệt, một phần boot của hệ điều hành, các ngoại vi và vùng nhớ do người dùng chỉ định,...đều nằm trên khu đất trống này. Hình dưới cho ta thấy thực tế các vùng nhớ tối đa mà các thành phần hệ thống được phân bố (tối đa 4GB ram), nhưng thực tế thì trên phần cứng chỉ có 1GB ram DDR3, nên ta phải sửa lại địa chỉ đầu cuối (0x0000000-0x3fffffff). Hình mũi tên xanh cho thấy vùng SDRAM window được phép điều chỉnh, ta sẽ điều chỉnh và cho 1 vùng ram trống để tương tác với custom IP.

<img width="746" height="519" alt="image" src="https://github.com/user-attachments/assets/7e77ff43-28a7-4472-8ca7-7f3d9da18d2d" />

Khi tương tác với thành phần bộ nhớ ngoài như SDRAM, cũng là bộ nhớ chính của hệ thống, cần lưu ý thao tác vì rất dễ làm treo hoặc panic hệ điều hành khi tương tác sai. Dưới đây là các bước sau khi đã đăng nhập thành công vào linux trên board SoC FPGA, hiện terminal để tương tác.

*bước 1*: Kiểm tra vùng hoạt động và quản lý của linux kernel
```cat /proc/iomem | grep -i "System RAM"```
Kết quả sẽ hiện ra như sau: 

<img width="1848" height="723" alt="image" src="https://github.com/user-attachments/assets/55f748e8-55ef-4df1-bb1d-1ca7f40b18ab" />

Kết quả mặc định thường sẽ là linux kernel quản lý full toàn bộ ram vật lý 1GB: từ 0x0000000 đến 0x3fffffff, nhưng ta có thể sửa lại bằng các lệnh sau ngay trên terminal của board:
```
# Gắn vùng fat của hệ thống từ thẻ sd
mkdir fat
mount /dev/mmcblk0p1 fat

# Mở trình soạn thảo để sửa nội dung file
nano fat/extlinux/extlinux.conf
```
Chép nội dung bên dưới tại vùng bắt đầu với APPEND

```
LABEL Linux Default
    KERNEL ../zImage
    FDT ../socfpga_cyclone5_de0_nano_soc.dtb
    APPEND root=/dev/mmcblk0p2 rw rootwait earlyprintk console=ttyS0,115200n8 net.ifnames=0 mem=512M
```

Sau khi dùng lệnh trên, linux kernel chỉ được phép quản lý và sử dụng 512MB vùng nhớ đầu (0x0000000-0x1fffffff), vùng nhớ 512 MB sau (0x20000000-3fffffff) sẽ là vùng nhớ an toàn để chúng ta ghi đè và đọc ra, các custom IP của ta cũng sẽ hoạt động ở vùng này. 

*bước 2*: HPS hay CPU ARM khuyến nghị sử dụng kiểu đánh dữ liệu little endian (byte có trọng số thấp thì nằm ở địa chỉ thấp). Lưu ý này áp dụng khi viết phần mềm, nếu không sẽ bị ngược chiều dữ liệu.

*bước 3*: Nắm rõ vùng địa chỉ hoạt động của các cây cầu (trong tài liệu Cyclone V Hard Processor System Technical Reference Manual) để tránh ghi nhầm. 

Các bước trên được minh họa như ảnh dưới: 
<img width="1852" height="727" alt="image" src="https://github.com/user-attachments/assets/85fc537e-59f7-4443-b224-db017cb6f231" />

## Nguyên lí DMA

- DMA (Direct Memory Access) là một khối chức năng được phép đọc và ghi dữ liệu trực tiếp vào MEMORY vật lý của hệ thống mà không cần sự can thiệp của CPU, giúp CPU rảnh tay hơn và thực hiện các nhiệm vụ khác thay vì phải làm một shipper cho RAM bất đắc dĩ. Khi có một yêu cầu ghi từ ngoại vi, ví dụ như UART, DMA sẽ luân chuyển từng byte dữ liệu vào mà không cần CPU. Khi có yêu cầu đọc, CPU cũng không cần tham gia, DMA sẽ đi vào bộ nhớ, đọc từng byte dữ liệu tại các địa chỉ, và gửi cho ngoại vi.
- Dĩ nhiên, DMA không tự thân nó biết được cần phải làm gì, do đó cần một bản mô tả chi tiết từ CPU để thực hiện, hay còn gọi là descriptor (bản mô tả), bản mô tả này gồm địa chỉ đầu, địa chỉ cuối, và độ rộng của dữ bus dữ liệu để DMA có thể biết và thực hiện chính xác.
- CPU đóng vai trò là master, khi muốn DMA hoạt động, nó gửi tín hiệu trigger để báo cho DMA biết, kèm với descriptor (có thể gửi ở dạng dữ liệu qua writedata hoặc gửi thẳng vào RAM kèm địa chỉ đích để DMA tự đọc).
- DMA đóng vai trò là master, còn SDRAM lúc này là slave, DMA phải tương tác với slave này qua chuẩn avalon master burst read, được mô tả trong tài liệu của Intel về chuẩn Avalon (Avalon Interface Specification) sẽ được nói ở phần kế tiếp.
- Sau khi thực hiện ghi và đọc tại vùng nhớ vật lý đã xong, DMA sẽ báo ngắt thông báo tới CPU, lúc này CPU sẽ tự động kiểm tra kết quả thông qua */dev/mem* tại vùng nhớ lưu kết quả hoặc có thể chờ một khoảng thời gian cố định để DMA thực thi xong bằng lệnh usleep rồi mới đọc kết quả.

**lưu ý**: Vì CPU có bộ nhớ đệm cache (L1,L2,L3) do đó nếu DMA ghi đè dữ liệu tại địa chỉ mà trước đó CPU đã từng đọc, CPU có thể lấy lại dữ liệu cũ đã lưu từ cache (cache hit) thay vì dữ liệu mới vừa được DMA được ghi vào RAM, do đó ta phải ép CPU phải lấy từ RAM thay vì lấy từ cache tại vùng nhớ mà DMA đã tương tác. Trong phần mềm, có thể dùng cờ 0_SYNC để báo cho CPU biết đây là vùng nhớ không cache.

Toàn bộ các bước trên minh họa như hình dưới:

<img width="1647" height="708" alt="image" src="https://github.com/user-attachments/assets/dd9ea4ee-18d9-4ab5-ad11-40bfec0b577a" />

## Nguyên lí các interface Avalon MM thông dụng

- Avalon là một kiến ​​trúc bus khá toàn diện, hỗ trợ nhiều loại giao dịch đa dạng. Khi muốn tối ưu hóa hiệu quả giao dịch (ví dụ: tăng lưu lượng dữ liệu), độ phức tạp của giao dịch cũng sẽ tăng lên. Độ phức tạp này còn phụ thuộc vào việc ta đang thiết kế thành phần Host (Master) hay Agent (Slave). Trong khi thành phần Agent chỉ cần phản hồi lại các tín hiệu từ Host, thì Host lại phải đảm nhận nhiều nhiệm vụ hơn: vừa phản hồi lại Agent, vừa quản lý bus để đảm bảo Agent nhận được các lệnh một cách chính xác.
- HPS SDRAM Controller (bộ điều khiển RAM DDR3 do HPS hay CPU quản lý) sử dụng giao diện Avalon MM Burst để thực hiện các giao dịch, do đó ở phần này ta sẽ tìm hiểu kĩ hơn về nó.

### Avalon MM read/write cơ bản
- Đối với một thành phần cần thực hiện thao tác đọc, tín hiệu tối thiểu bắt buộc phải có để tuân thủ các thông số kỹ thuật của bus Avalon là `readdata`.

- Đối với một thành phần cần thực hiện thao tác ghi, các tín hiệu tối thiểu bắt buộc là `write` và `writedata`.

- Hướng luồng thông tin sẽ quyết định bên nào đóng vai trò là agent (tác nhân) và bên nào là host (chủ). Tín hiệu `readdata` luôn truyền từ agent sang host, trong khi `writedata` luôn truyền từ host sang agent.

Ví dụ, nếu chúng ta có một thành phần chủ (host component) tối giản để đọc dữ liệu từ thiết bị tớ (slave), thì các yêu cầu tối thiểu sẽ như được trình bày như hình dưới.

<img width="426" height="200" alt="image" src="https://github.com/user-attachments/assets/13cbd5d0-1a82-43c4-a02b-94b4a734a8cc" />

Trong trường hợp này, agent luôn trả về một giá trị tại cổng `readdata`, và host chỉ cần lấy mẫu giá trị đó khi cần thiết. Thông thường, chúng ta cần thêm các tín hiệu để thiết lập cơ chế giao tiếp giữa host và agent. Một số tình huống điển hình mà bus Avalon hỗ trợ bao gồm:

   * Agent có thể trả về nhiều giá trị, do đó cần có cơ chế đánh địa chỉ; vì vậy, ta sẽ cần đến tín hiệu địa chỉ (address signal).
   * Có thể agent cũng cần thực hiện các thao tác đọc và ghi.
   * Có thể agent cần một số chu kỳ xung nhịp để chuẩn bị dữ liệu sẵn sàng cho host đọc; trong trường hợp này, ta có thể sử dụng tín hiệu `waitrequest`.

- Các hình minh họa bên dưới mô tả về các interface đọc/ghi cơ bản:

  <img width="891" height="638" alt="image" src="https://github.com/user-attachments/assets/a9c80e8c-2361-4843-9194-9aefaf54a6fc" />


