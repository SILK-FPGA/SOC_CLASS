#Các vùng nhớ trên SDRAM
SDRAM là thành phần bộ nhớ đặc biệt, một phần boot của hệ điều hành, các ngoại vi và vùng nhớ do người dùng chỉ định,...đều nằm trên khu đất trống này. Hình dưới cho ta thấy thực tế các vùng nhớ tối đa mà các thành phần hệ thống được phân bố (tối đa 4GB ram), nhưng thực tế thì trên phần cứng chỉ có 1GB ram DDR3, nên ta phải sửa lại địa chỉ đầu cuối (0x0000000-0x3fffffff)

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
