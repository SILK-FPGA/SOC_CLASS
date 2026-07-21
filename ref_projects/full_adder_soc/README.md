## LAB1: Thiết kế một bộ cộng đơn giản bên miền FPGA, thiết kế giao diện avalon-mm, kết nối với HPS và viết code C điều khiển

<img width="1003" height="448" alt="image" src="https://github.com/user-attachments/assets/7f035819-68e9-4838-9a71-8052c5b2be9b" />

*Các bước tiếp cận* 
1) Đầu tiên, ta cần xác định 3 điểm mấu chốt cần thiết kế: sử dụng cây cầu nào (h2f light weight, h2f heavy weight, f2h, f2sdram), giao thức nào (avalon hay axi) và phương thức nào (memory-mapped hay streaming).
2) Ta cần bọc bên ngoài khối IP mà ta đã viết giao diện avalon. Để có thể kết nối vào interconnect.
3) Sử dụng Plaform designer để kết nối hệ thống. Export các chân ra ngoài nếu cần thiết. 
4) Ánh xạ các slave thành các địa chỉ riêng biệt, không đè lên nhau, và có độ rộng hợp lệ.
5) Kiểm tra trạng thái của linux kernel, kiểm tra device tree, kiểm tra các cây cầu đã enable chưa.
6) Biên dịch hệ thống thành file .rbf, viết code C và kiểm tra hệ thống.
   
## Thiết kế phần cứng
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

     coe (Conduit Export) - Dùng cho các tín hiệu ngoại vi nối ra ngoài.
```

- Trong thiết kế của LAB này, sử dụng cầu h2f heavy weight giao diện axi (h2f_axi_master), cây cầu này có độ rộng được lựa chọn là 64 bit. Như hình dưới.

<img width="1452" height="730" alt="image" src="https://github.com/user-attachments/assets/0d6419a8-4e9c-40f6-b6f9-a473443a14e2" />

**Hoàn toàn có thể chọn cầu lightweight (32 bit) để tương thích với thiết kế, hoặc có thể chỉnh độ rộng của a, b, sum lên 64 bit để tương thích với cầu**
- Khi kết nối cần đảm bảo các chân của clk và reset đều được nối vào, error báo ở góc dưới cùng bên trái phải bằng 0. Các master phải nối vào slave mà nó muốn điều khiển. Như hình dưới.

<img width="1853" height="989" alt="image" src="https://github.com/user-attachments/assets/44da9bfe-53b3-4a5f-b7e4-887a899fede9" />

- Lưu lại với ctrl+S, generate HDL code là xong.

## Thiết kế phần mềm

- Toàn bộ tài liệu tham khảo anh để trong notebooklm, các bạn có thể lên lên đó hỏi cho tiện, hoặc bấm vào link này để tra cứu [CYCLONE V HPS] (https://docs.altera.com/r/docs/683126/21.2/cyclone-v-hard-processor-system-technical-reference-manual/cyclone-v-hard-processor-system-technical-reference-manual-revision-history).
- Việc thiết kế phần mềm, ta cần biết địa chỉ của các cây cầu. Ở đây ta cần xác định địa chỉ của cầu h2f_heavyweight_axi_master. Như hình dưới đây, cây cầu này có địa chỉ gốc là 0xC000000:
  
<img width="1448" height="311" alt="image" src="https://github.com/user-attachments/assets/b915ed91-4822-460b-aaa9-3a2507e825db" />

- Tiếp đên ta cần một file header *'hps_0.h'* để dịch các địa chỉ gốc (base address) thành các macro trong ngôn ngữ C để ta lập trình cho CPU. Trong thư mục chứa file .qpf, sau khi generate xong phần cứng SoC, file *'soc_system.sopcinfo'* sẽ được tạo ra, đây là nguyên liệu để xào nấu ra file *'hps_0.h'.
- Để chạy được các bước tạo file header dưới đây, trước tiên cần tải SoC EDS Standard 20.1 (linux) và WSL :
  ``` ~/intelFPGA_lite/20.1/embedded/embedded_command_shell.sh
       cd full_adder_soc/
       sopc-create-header-files "soc_system.sopcinfo" --single hps_0.h --module hps_0
  ```
- **Nội dung của file hps_0.h sau khi tạo ra như sau**:
```
#ifndef _ALTERA_HPS_0_H_
#define _ALTERA_HPS_0_H_

#define PIO64_OUT_1_COMPONENT_TYPE pio64_out
#define PIO64_OUT_1_COMPONENT_NAME pio64_out_1
#define PIO64_OUT_1_BASE 0x0
#define PIO64_OUT_1_SPAN 8
#define PIO64_OUT_1_END 0x7

#define PIO64_OUT_0_COMPONENT_TYPE pio64_out
#define PIO64_OUT_0_COMPONENT_NAME pio64_out_0
#define PIO64_OUT_0_BASE 0x8
#define PIO64_OUT_0_SPAN 8
#define PIO64_OUT_0_END 0xf

#define PIO64_IN_0_COMPONENT_TYPE pio64_in
#define PIO64_IN_0_COMPONENT_NAME pio64_in_0
#define PIO64_IN_0_BASE 0x10
#define PIO64_IN_0_SPAN 8
#define PIO64_IN_0_END 0x17

#define SYSID_QSYS_COMPONENT_TYPE altera_avalon_sysid_qsys
#define SYSID_QSYS_COMPONENT_NAME sysid_qsys
#define SYSID_QSYS_BASE 0x1000
#define SYSID_QSYS_SPAN 8
#define SYSID_QSYS_END 0x1007
#define SYSID_QSYS_ID 2899645186
#define SYSID_QSYS_TIMESTAMP 1766564740

#define JTAG_UART_COMPONENT_TYPE altera_avalon_jtag_uart
#define JTAG_UART_COMPONENT_NAME jtag_uart
#define JTAG_UART_BASE 0x2000
#define JTAG_UART_SPAN 8
#define JTAG_UART_END 0x2007
#define JTAG_UART_IRQ 2
#define JTAG_UART_READ_DEPTH 64
#define JTAG_UART_READ_THRESHOLD 8
#define JTAG_UART_WRITE_DEPTH 64
#define JTAG_UART_WRITE_THRESHOLD 8

#define DIPSW_PIO_COMPONENT_TYPE altera_avalon_pio
#define DIPSW_PIO_COMPONENT_NAME dipsw_pio
#define DIPSW_PIO_BASE 0x4000
#define DIPSW_PIO_SPAN 16
#define DIPSW_PIO_END 0x400f
#define DIPSW_PIO_IRQ 0
#define DIPSW_PIO_BIT_CLEARING_EDGE_REGISTER 1
#define DIPSW_PIO_BIT_MODIFYING_OUTPUT_REGISTER 0
#define DIPSW_PIO_CAPTURE 1
#define DIPSW_PIO_DATA_WIDTH 4
#define DIPSW_PIO_DO_TEST_BENCH_WIRING 0
#define DIPSW_PIO_DRIVEN_SIM_VALUE 0
#define DIPSW_PIO_EDGE_TYPE ANY
#define DIPSW_PIO_FREQ 50000000
#define DIPSW_PIO_HAS_IN 1
#define DIPSW_PIO_HAS_OUT 0
#define DIPSW_PIO_HAS_TRI 0
#define DIPSW_PIO_IRQ_TYPE EDGE
#define DIPSW_PIO_RESET_VALUE 0

#define BUTTON_PIO_COMPONENT_TYPE altera_avalon_pio
#define BUTTON_PIO_COMPONENT_NAME button_pio
#define BUTTON_PIO_BASE 0x5000
#define BUTTON_PIO_SPAN 16
#define BUTTON_PIO_END 0x500f
#define BUTTON_PIO_IRQ 1
#define BUTTON_PIO_BIT_CLEARING_EDGE_REGISTER 1
#define BUTTON_PIO_BIT_MODIFYING_OUTPUT_REGISTER 0
#define BUTTON_PIO_CAPTURE 1
#define BUTTON_PIO_DATA_WIDTH 2
#define BUTTON_PIO_DO_TEST_BENCH_WIRING 0
#define BUTTON_PIO_DRIVEN_SIM_VALUE 0
#define BUTTON_PIO_EDGE_TYPE FALLING
#define BUTTON_PIO_FREQ 50000000
#define BUTTON_PIO_HAS_IN 1
#define BUTTON_PIO_HAS_OUT 0
#define BUTTON_PIO_HAS_TRI 0
#define BUTTON_PIO_IRQ_TYPE EDGE
#define BUTTON_PIO_RESET_VALUE 0

#define ILC_COMPONENT_TYPE interrupt_latency_counter
#define ILC_COMPONENT_NAME ILC
#define ILC_BASE 0x30000
#define ILC_SPAN 256
#define ILC_END 0x300ff


#endif /* _ALTERA_HPS_0_H_ */
```

>> Ta bóc tách nội dung dưới đây địa chỉ của số a (kết nối bởi PIO_OUT_1) và số b (kết nối bởi PIO_OUT_0), kết quả của phép cộng (kết nối bởi PIO_IN_1).
>>  _BASE (offset): Đây không phải là địa chỉ vật lý tuyệt đối, mà là khoảng cách (offset) tính từ đầu ra của cây cầu Master mà IP đó được cắm vào.
>> _SPAN (Độ phân giải): Số byte mà thiết bị đó chiếm giữ trên bản đồ bộ nhớ. Ở đây SPAN là 8, tương đương 64-bit (8 bytes), khớp hoàn toàn với lõi PIO 64-bit.
>> _END: Điểm kết thúc của IP đó (BASE + SPAN - 1).

```
#define PIO64_OUT_1_COMPONENT_TYPE pio64_out
#define PIO64_OUT_1_COMPONENT_NAME pio64_out_1
#define PIO64_OUT_1_BASE 0x0
#define PIO64_OUT_1_SPAN 8
#define PIO64_OUT_1_END 0x7
```
```
#define PIO64_OUT_0_COMPONENT_TYPE pio64_out
#define PIO64_OUT_0_COMPONENT_NAME pio64_out_0
#define PIO64_OUT_0_BASE 0x8
#define PIO64_OUT_0_SPAN 8
#define PIO64_OUT_0_END 0xf
```
**Code phần mềm hệ thống tích hợp header hps_0.h tạo sẵn viết bằng C, full_adder.c**
```
//thư viện cần thiết để hệ thống chạy mượt trên linux
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <inttypes.h>
#include <errno.h>
//thêm hps_0.h để định nghĩa các macro, nếu không thêm vào thì có thể dán toàn bộ nội dung file vào đây.
#include <hps_0.h>
// Địa chỉ vật lý của cầu HPS-to-FPGA (Heavyweight Bridge)
#define H2F_BRIDGE_BASE 0xC0000000

// Kích thước vùng nhớ cần ánh xạ. 
// PIO cuối cùng (PIO64_IN_0) kết thúc ở 0x17. 
// Ta lấy 0x20 (32 bytes) hoặc 4096 (Page size) cho an toàn.
#define H2F_BRIDGE_SPAN 0x1000 

int main(int argc, char **argv) {
    int fd;
    void *virtual_base;
    
    // Khai báo các con trỏ trỏ tới thanh ghi phần cứng
    // Sử dụng 'volatile' để báo cho trình biên dịch biết giá trị có thể thay đổi ngoài ý muốn (do phần cứng)
    volatile uint64_t *pio_a_ptr = NULL;
    volatile uint64_t *pio_b_ptr = NULL;
    volatile uint64_t *pio_sum_ptr = NULL;

    uint64_t num_a = 0;
    uint64_t num_b = 0;
    uint64_t sum = 0;

    // 1. Kiểm tra tham số đầu vào
    if (argc != 3) {
        printf("Usage: %s <number_a> <number_b>\n", argv[0]);
        return -1;
    }

    // Chuyển đổi chuỗi sang số 64-bit
    num_a = strtoull(argv[1], NULL, 10);
    num_b = strtoull(argv[2], NULL, 10);

    // 2. Mở file /dev/mem để truy cập bộ nhớ vật lý
    // O_SYNC là bắt buộc để đảm bảo ghi/đọc trực tiếp xuống phần cứng không qua Cache
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("ERROR: Could not open /dev/mem");
        return -1;
    }

    // 3. Ánh xạ địa chỉ vật lý sang địa chỉ ảo (User Space)
    virtual_base = mmap(NULL, H2F_BRIDGE_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, H2F_BRIDGE_BASE);   
    if (virtual_base == MAP_FAILED) {
        perror("ERROR: mmap() failed");
        close(fd);
        return -1;
    }

    // 4. Tính toán địa chỉ ảo cho từng thanh ghi dựa trên Macro trong hps_0.h
    // Lưu ý: Phải ép kiểu về (uint8_t *) trước khi cộng offset để tính đúng theo byte
    // PIO64_OUT_1 (Base 0x0) -> Đóng vai trò số A
    pio_a_ptr = (uint64_t *)((uint8_t *)virtual_base + PIO64_OUT_1_BASE);
    // PIO64_OUT_0 (Base 0x8) -> Đóng vai trò số B
    pio_b_ptr = (uint64_t *)((uint8_t *)virtual_base + PIO64_OUT_0_BASE);
    // PIO64_IN_0 (Base 0x10) -> Đóng vai trò Tổng (Sum)
    pio_sum_ptr = (uint64_t *)((uint8_t *)virtual_base + PIO64_IN_0_BASE);

    // 5. Thực hiện Ghi và Đọc phần cứng
    printf("Hardware Adder Interface:\n");
    printf("Writing A = %" PRIu64 " to Offset 0x%X\n", num_a, PIO64_OUT_1_BASE);
    printf("Writing B = %" PRIu64 " to Offset 0x%X\n", num_b, PIO64_OUT_0_BASE);

    *pio_a_ptr = num_a; // Ghi xuống FPGA
    *pio_b_ptr = num_b; // Ghi xuống FPGA
     sum = *pio_sum_ptr;// Đọc kết quả từ FPGA
    printf("Result read from Offset 0x%X: Sum = %" PRIu64 "\n", PIO64_IN_0_BASE, sum);
    // 6. Dọn dẹp và thoát
    if (munmap(virtual_base, H2F_BRIDGE_SPAN) != 0) {
        perror("ERROR: munmap() failed");
        close(fd);
        return -1;
    }
    close(fd);
    return 0;
}
```
**Code phần mềm hệ thống, không sử dụng header hps_0.h, viết bằng C** 
#include <error.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

#define BRIDGE 0xC0000000
#define BRIDGE_SPAN 0x18

#define ADDER_A 0x00
#define ADDER_B 0x08
#define ADDER_SUM 0x10

int main(int argc, char **argv) {
  uint64_t a = 0;
  uint64_t b = 0;
  uint64_t sum = 0;

  uint8_t *a_map = NULL;
  uint8_t *b_map = NULL;
  uint8_t *sum_map = NULL;

  uint8_t *bridge_map = NULL;

  int fd = 0;
  int result = 0;

  if (argc != 3) {
    perror("Only 2 numbers should be passed.");
    return -1;
  }

  a = strtoll(argv[1], NULL, 10);
  b = strtoll(argv[2], NULL, 10);

  fd = open("/dev/mem", O_RDWR | O_SYNC);

  if (fd < 0) {
    perror("Couldn't open /dev/mem\n");
    return -2;
  }

  bridge_map = (uint8_t *)mmap(NULL, BRIDGE_SPAN, PROT_READ | PROT_WRITE,
                               MAP_SHARED, fd, BRIDGE);

  if (bridge_map == MAP_FAILED) {
    perror("mmap failed.");
    close(fd);
    return -3;
  }

  a_map = bridge_map + ADDER_A;
  b_map = bridge_map + ADDER_B;
  sum_map = bridge_map + ADDER_SUM;

  *((uint64_t *)a_map) = a;
  *((uint64_t *)b_map) = b;
  sum = *((uint64_t *)sum_map);

  printf("%" PRIu64 "\n", sum);

  result = munmap(bridge_map, BRIDGE_SPAN);

  if (result < 0) {
    perror("Couldnt unmap bridge.");
    close(fd);
    return -4;
  }

  close(fd);
  return 0;
}
```


