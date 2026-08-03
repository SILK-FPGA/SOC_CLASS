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
