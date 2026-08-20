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

### Avalon MM Basic Read/Write

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

Phần này anh đã nói trong buổi học, nên mô tả trong này sẽ khá dài, các bạn chịu khó xem lại video bài giảng để nắm kĩ hơn nhé.

### Avalon MM Pipelined Read/Write
Xét về mặt hình thức, sự khác biệt duy nhất giữa giao dịch dạng đường ống (pipelined) và giao dịch cơ bản (basic) chỉ nằm ở tín hiệu `readdatavalid`. Tuy nhiên, sự hiện diện của tín hiệu này lại tạo ra sự thay đổi mang tính quyết định.

<img width="1315" height="345" alt="image" src="https://github.com/user-attachments/assets/8faecbe4-dbfc-41d3-9fb7-72401310704b" />

- Khi agent kích hoạt tín hiệu `waitrequest`, host cần giữ nguyên trạng thái của các tín hiệu địa chỉ và tín hiệu đọc.
- Khi agent hủy kích hoạt tín hiệu `waitrequest`, host có thể tiếp tục duy trì tín hiệu đọc ở mức c
- ao và cung cấp thêm các địa chỉ để agent phản hồi dữ liệu.
- Host không bắt buộc phải chờ agent phản hồi dữ liệu cho một địa chỉ cụ thể nào đó trước khi yêu cầu thêm dữ liệu; host có thể thực hiện các yêu cầu và nhận phản hồi một cách song song.
- Bất cứ khi nào có dữ liệu để phản hồi, agent sẽ kích hoạt tín hiệu `readdatavalid` và đưa dữ liệu vào tín hiệu `readdata` cho đến sườn dương tiếp theo của xung nhịp (`clk`) – thời điểm mà host sẽ lấy mẫu dữ liệu từ `readdata`.
- Các phản hồi tiếp theo từ agent cũng được host thu nhận theo cách tương tự, tức là khi tín hiệu `readdatavalid` chuyển sang mức cao. Dữ liệu được trả về theo đúng thứ tự tương ứng với các địa chỉ đã được gửi đi.

Phần này anh đã nói trong buổi học, nên mô tả trong này sẽ khá dài, các bạn chịu khó xem lại video bài giảng để nắm kĩ hơn nhé.

### Avalon MM Burst Read/Write

- Giao dịch dạng Burst (truyền dữ liệu theo khối) được phát triển dựa trên giao dịch dạng Pipelined (đường ống) với việc bổ sung thêm tín hiệu `burstcount`. Host sử dụng tín hiệu này để yêu cầu Agent trả về một số lượng đơn vị dữ liệu hoặc từ (word) nhất định. Kích thước của mỗi từ tương ứng với kích thước của tín hiệu `readdata`. Do đó, cơ chế này đặc biệt hữu ích cho các yêu cầu truy cập bộ nhớ (chẳng hạn như SDRAM), nơi cần lấy dữ liệu từ các ô nhớ liên tiếp bắt đầu từ một địa chỉ cụ thể.

- Vì giao diện Burst cũng là một dạng giao diện Pipelined, nên các đặc tính hoạt động còn lại hoàn toàn giống với giao diện Pipelined. Điểm khác biệt duy nhất là ta chỉ cần cung cấp một giá trị địa chỉ duy nhất.

  <img width="1295" height="415" alt="image" src="https://github.com/user-attachments/assets/7f77e98d-c1ed-40aa-b00c-5e474353b72c" />

### Avalon MM Bidirectional Port Signals for SDRAM Controller

Dưới đây là các chân tín hiệu 2 chiều mà thành phần Host (Master) cần có để giao tiếp với SDRAM, nằm trong tài liệu Cyclone V Hard Processor System Technical Reference Manual, chương FPGA-to-SDRAM Protocol Details:

<img width="1021" height="791" alt="image" src="https://github.com/user-attachments/assets/64717c1d-c385-4fc0-8fd3-2674e3fcfc63" />

## Custom DMA IP

### Harware Design
Ta sẽ xem flow của hệ thống như sơ đồ bên dưới với trình tự thực hiện từ 0 tới 5

<img width="1300" height="666" alt="image" src="https://github.com/user-attachments/assets/387648f2-c4e9-44f3-84fd-4f725bbba533" />



- O. Đầu tiên CPU dùng file /dev/mem để mở vùng RAM vật lý, ghi 2 giá trị a và b vào 2 địa chỉ vật lý liền kề nhau trong RAM.
- 1. CPU báo cờ do read lên 1 và gửi mô tả thông qua thanh ghi ctrl reg cho DMA (avalon_control + avalon_sdr) bắt đầu việc đọc ra từ RAM. Lúc này CPU đóng vai trò là Host, thông qua interface avalon memory-mapped để gửi cho agent avalon_control. Vai trò của agent này là đứng ngay biên giới giữa HPS và FPGA, thiết lập các interface của avalon mm slave để nhận đúng dữ liệu từ CPU.
- 2. avalon_control dùng gửi lại các mô tả từ CPU mà nó nhận được cho avalon_sdr, avalon sdr sau khi nhận được cờ sẽ bắt đầu vào trạng thái đọc từ RAM như một avalon mm master.
- 3. avalon_sdr nhận dữ liệu từ RAM qua chân sdram data thông qua interface avalon mm master.
- 4. avalon_sdr gửi `adder_a` và `adder b` qua cho khối adder nhận và xử lí.
- 5. adder sau khi xử lí xong liền gửi kết quả cho pio32 lưu kết quả, sau 1 khoảng thời gian, CPU phát 1 lệnh đọc xuống cầu h2f_axi_master, vào vùng của FPGA, đi qua cầu mm_bridge_0 (đang nối thẳng vào pio32_0) để lôi dữ liệu ra.

Bên trong avalon_sdr, một máy trạng thái được thiết kế để liên tục đọc dữ liệu ngay khi có cờ `do_read` = 1, `wait_request` là tín hiệu từ RAM yêu cầu Host phải chờ khi nó chưa sẵn sàng gửi, `readdatavalid` là cờ báo dữ liệu `readdata` trả về từ Agent RAM là hợp lệ. Hình minh họa về máy trạng thái như bên dưới.

<img width="960" height="720" alt="image" src="https://github.com/user-attachments/assets/9a4f18ab-fec5-48b3-bb44-12ee9ecbdf1d" />

Các chân tín hiệu trong code verilog nằm trong thư mục ip/ddr3/avalon_sdr.sv 
- Từ Agent --> Host:
  - `avm_m0_waitrequest`: cờ báo Agent chưa sẵn sàng để nhận địa chỉ `avm_m0_address` từ Host gửi tới.
  - `avm_m0_readdata`: dữ liệu đọc ra từ RAM sẽ nằm trên bus dữ liệu này.
  - `avm_m0_readdatavalid`: cờ báo dữ liệu đọc ra từ RAM là hợp lệ, gửi cùng chu kì có `avm_m0_readdata`.
- Từ Host --> Agent:
  - `avm_m0_address`: Địa chỉ đọc dữ liệu từ Agent.
  - `avm_m0_read`: Yêu cầu đọc dữ liệu từ Agent.
  - `avm_m0_byteenable`: Mặt nạ dùng cho việc ghi dữ liệu vào Agent
  - `avm_m0_burstcount`: Số lượng các ô địa chỉ liền kề cần đọc ra từ Agent. vd: burstcount: 4, địa chỉ bắt đầu là 0x20000000, thì nó đọc tới 0x20000003 thì dừng.
  - `avm_m0_address`: Địa chỉ bắt đầu đọc.

  Chi tiết hơn về 2 đoạn code của avalon_control và avalon_sdr các bạn xem lại video bài giảng, code verilog anh để trong thư mục /ip/ddr3/ ngay tại thư mục này.

  **Tiếp theo là phần nối dây bên trong platform designer**:
  
  <img width="1414" height="776" alt="image" src="https://github.com/user-attachments/assets/e263ba91-cd6d-4fb3-9455-ae3809f86e43" />

Trong hình trên ta có các khối như sau:
- **hps_0** là AXI Master, tương tác với slave **avalon_control_0**, **mm_bridge_0**
- **avalon_sdr_0** là Avalon MM Master nối vào SDRAM DDR3 đang là Avalon MM Slave thông qua `f2h_sdram0_data` bên trong hps_0.
- **mm_bridge_0** vừa là Avalon MM Master (đối với **pio32_0**) vừa là Avalon MM Slave (đối với **hps_0**), địa chỉ offset bắt đầu từ 0x1000 đến 0x13FF (so với cây cầu h2f_axi_master [0xC0000000]).
- **avalon_control_0** là Avalon MM Slave, địa chỉ offset bắt đầu từ 0x0000 đến 0x0003 (so với cây cầu h2f_axi_master [0xC0000000]).
- **pio32_0** là Avalon MM Slave, địa chỉ offset bát đầu từ 0x0000 đến 0x0003 (so với cây cầu **mm_bridge_0**).

Khi đó ta có bảng địa chỉ như sau:


#### **1. Bảng phân cấp địa chỉ chi tiết**

| Tên IP Slave | Giao tiếp Slave | Trực thuộc Master | Địa chỉ Offset (so với Master) | Địa chỉ vật lý tuyệt đối (Code C) | Dải địa chỉ vật lý chiếm dụng |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`avalon_control_0`** | Avalon MM Slave (`s0`) | `hps_0.h2f_axi_master` | `0x0000_0000` | **`0xC0000000`** | `0xC0000000` – `0xC0000003` |
| **`mm_bridge_0`** | Avalon MM Slave (`s0`) | `hps_0.h2f_axi_master` | `0x0000_1000` | **`0xC0001000`** | `0xC0001000` – `0xC00013FF` |
| **`pio32_0`** | Avalon MM Slave (`s0`) | `mm_bridge_0.m0` | `0x0000_0000` | **`0xC0001000`** | `0xC0001000` – `0xC0001003` |
| **DDR3 SDRAM** | Avalon MM Slave | `avalon_sdr_0.m0` | `0x0000_0000` | **`0x20000000`** *(Vùng Data Test)* | `0x00000000` – `0xFFFFFFFF` |

---

#### **2. Công thức tính toán địa chỉ phân cấp**

* **Đối với `avalon_control_0`:**
  $$\text{Physical Address} = \text{Base}_{H2F} + \text{Offset}_{\text{avalon\_control}}$$
  $$\text{Physical Address} = \mathtt{0xC0000000} + \mathtt{0x00000000} = \mathbf{\mathtt{0xC0000000}}$$

* **Đối với `mm_bridge_0` (Pipeline Bridge):**
  $$\text{Physical Address} = \text{Base}_{H2F} + \text{Offset}_{\text{mm\_bridge}}$$
  $$\text{Physical Address} = \mathtt{0xC0000000} + \mathtt{0x00001000} = \mathbf{\mathtt{0xC0001000}}$$

* **Đối với `pio32_0` (Đi qua Bridge):**
  $$\text{Physical Address} = \text{Base}_{H2F} + \text{Offset}_{\text{mm\_bridge}} + \text{Offset}_{\text{pio32}}$$
  $$\text{Physical Address} = \mathtt{0xC0000000} + \mathtt{0x00001000} + \mathtt{0x00000000} = \mathbf{\mathtt{0xC0001000}}$$

* **Đối với `DDR3 SDRAM` (Truy cập qua F2S Bridge):**
  Khối Custom DMA (`avalon_sdr_0`) làm Master cắm trực tiếp vào cầu `f2h_sdram0_data`, không đi qua cầu H2F. Khi code C nạp tham số địa chỉ `0x20000000`, DMA sẽ truy cập thẳng tới offset **512MB** trên thanh RAM vật lý.

# Software Design
```
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <time.h>

// ĐỊA CHỈ VẬT LÝ (PHYSICAL ADDRESS) 
//  H2F Bridge
#define HW_REGS_BASE        0xC0000000
#define HW_REGS_SPAN        0x2000      // Map 8KB 
#define HW_REGS_MASK        (HW_REGS_SPAN - 1)

// Offset của các IP so với HW_REGS_BASE
#define AVALON_CONTROL_OFFSET  0x0000
#define PIO_RESULT_OFFSET      0x1000   

// Vùng dữ liệu SDRAM (Nơi chứa số hạng A, B)
#define SDRAM_TARGET_ADDR   0x20000000
#define SDRAM_SPAN          0x1000      // Map 4KB 
#define SDRAM_MASK          (SDRAM_SPAN - 1)

int main() {
    int fd;
    void *virtual_base_regs;
    void *virtual_base_sdram;
    
    volatile uint32_t *ctrl_ptr;
    volatile uint32_t *pio_ptr;
    volatile uint32_t *ram_ptr;

    uint32_t val_A, val_B, expected_sum, actual_sum;

    // Mở file /dev/mem để truy cập bộ nhớ vật lý
    if ((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        perror("FATAL: Couldn't open /dev/mem");
        return 1;
    }

    // =============================================================
    // MAP ĐỊA CHỈ VÙNG ĐIỀU KHIỂN (FPGA PERIPHERALS)
    // =============================================================
    virtual_base_regs = mmap(NULL, HW_REGS_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, HW_REGS_BASE);
    if (virtual_base_regs == MAP_FAILED) {
        perror("FATAL: mmap regs failed");
        close(fd);
        return 1;
    }

    // Ánh xạ con trỏ 
    ctrl_ptr = (uint32_t *)(virtual_base_regs + AVALON_CONTROL_OFFSET);
    pio_ptr  = (uint32_t *)(virtual_base_regs + PIO_RESULT_OFFSET);

    // =============================================================
    // MAP ĐỊA CHỈ VÙNG SDRAM (DATA)
    // =============================================================
    
    virtual_base_sdram = mmap(NULL, SDRAM_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, SDRAM_TARGET_ADDR);
    if (virtual_base_sdram == MAP_FAILED) {
        perror("FATAL: mmap sdram failed");
        close(fd);
        return 1;
    }
    
    ram_ptr = (uint32_t *)virtual_base_sdram;

    // =============================================================
    // CHUẨN BỊ DỮ LIỆU TEST
    // =============================================================
    srand(time(NULL));
    val_A = rand() % 100; // Số ngẫu nhiên 0-99
    val_B = rand() % 100;
    expected_sum = val_A + val_B;

    printf("----------------------------------------\n");
    printf("[SW] Writing to SDRAM @ 0x%08X\n", SDRAM_TARGET_ADDR);
    
    // Ghi vào 2 ô nhớ liên tiếp (32-bit mỗi ô)
    // ram_ptr[0] tương ứng 0x20000000
    // ram_ptr[1] tương ứng 0x20000004
    *(ram_ptr + 0) = val_A;
    *(ram_ptr + 1) = val_B;

    printf("     Addr 0x%08X = %d\n", SDRAM_TARGET_ADDR, val_A);
    printf("     Addr 0x%08X = %d\n", SDRAM_TARGET_ADDR + 4, val_B);
    printf("     Expected Sum   = %d\n", expected_sum);

    // =============================================================
    // CẤU HÌNH AVALON CONTROL & TRIGGER
    // =============================================================
    // Cấu trúc Register:
    // [31:12] Init Addr (20 bit)
    // [11:1]  Burst Length (11 bit)
    // [0]     Do Read (1 bit)
    
    uint32_t init_addr_val = (SDRAM_TARGET_ADDR >> 12); // Lấy 20 bit cao (bỏ 12 bit thấp)
    uint32_t burst_len_val = 2;                         // Đọc 2 số
    
    // Tạo giá trị điều khiển
    uint32_t control_word = (init_addr_val << 12) | (burst_len_val << 1);
    
    // Reset control (do_read = 0)
    *ctrl_ptr = control_word | 0;
    
    printf("[SW] Triggering FPGA Hardware Accelerator...\n");
    // Trigger (do_read = 1)
    *ctrl_ptr = control_word | 1;

    
    usleep(100); 

    // Tắt bit do_read 
    *ctrl_ptr = control_word | 0;

    // =============================================================
    // ĐỌC KẾT QUẢ TỪ PIO
    // =============================================================
    actual_sum = *pio_ptr;

    printf("[HW] Result read from PIO (0xC0001000): %d\n", actual_sum);

    if (actual_sum == expected_sum) {
        printf("\n✅ SUCCESS: Hardware result matches Software calculation!\n");
    } else {
        printf("\n❌ FAILURE: Mismatch! Expected %d, got %d\n", expected_sum, actual_sum);
    }
    printf("----------------------------------------\n");

    // Dọn dẹp
    if (munmap(virtual_base_regs, HW_REGS_SPAN) != 0) perror("munmap regs failed");
    if (munmap(virtual_base_sdram, SDRAM_SPAN) != 0) perror("munmap sdram failed");
    close(fd);

    return 0;
}

```
## OUTPUT ON FPGA

Kết quả sau khi nạp device tree overlay như hình dưới, cách nạp động qua device tree overlay các bạn xem trong thư mục /docs, file dynamic_device_tree_overlay.md nha:

<img width="1414" height="809" alt="image" src="https://github.com/user-attachments/assets/cfa30094-c1cc-4b7e-b0c0-a956bf4bdfeb" />

Thử ghi vào 2 số ngẫu nhiên, rồi đọc ra từ địa chỉ cầu H2F 0xC0000000, ta được kết quả tính toán từ phần cứng adder (custom IP) y hệt như kết quả trên phần mềm.

## CHẠY TRÊN WEB REMOTE LAB

Đầu tiên ta nạp file output_files/final_rbf/output_file.rbf tại thư mục dự án của github này: 

<img width="1202" height="855" alt="image" src="https://github.com/user-attachments/assets/c9f0f25d-4a7c-41f3-be98-874ef3b243b4" />

Nếu upload thành công, mở terminal lên kiểm tra, ấn enter liên tục, nếu không treo --> nạp thành công, hoặc có thể kiểm tra trạng thái của board, có led debug clock đang nháy

<img width="1284" height="786" alt="image" src="https://github.com/user-attachments/assets/685cd881-3d4f-4415-9063-d51238859ae9" />

Sau khi mở terminal, tại root ~/ chạy lệnh "run c"


<img width="1284" height="818" alt="image" src="https://github.com/user-attachments/assets/762165bb-56f8-418b-ac50-0f494728a40f" />

Copy code mẫu tại github này: /software/userspace/ddr3_adder.c , trước tiên phải 'ctrl + K' để xóa code mẫu cũ, 'ctrl + shift + V' để dán code mới vào


