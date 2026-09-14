#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <time.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// ----------------------------------------------------
// ĐỊA CHỈ HỆ THỐNG
// ----------------------------------------------------
#define HW_REGS_BASE        0xFF200000
#define HW_REGS_SPAN        0x00200000
#define HW_REGS_MASK        (HW_REGS_SPAN - 1)

// Địa chỉ dựa trên file Qsys
#define MSGDMA_WRITE_CSR    0x0000
#define MSGDMA_WRITE_DESC   0x0040
#define MSGDMA_READ_CSR     0x0020
#define MSGDMA_READ_DESC    0x0050

#define SDRAM_BASE          0x30000000
#define SDRAM_SPAN          0x02000000 
#define INPUT_OFFSET        0x00000000 
#define OUTPUT_OFFSET       0x01000000 


#define IORD(base, offset)        (*((volatile uint32_t *)((uint8_t *)(base) + (offset))))
#define IOWR(base, offset, data)  (*((volatile uint32_t *)((uint8_t *)(base) + (offset))) = (data))


void dump_dma_status(void *lw_base, const char* name, uint32_t csr_offset) {
    uint32_t status = IORD(lw_base, csr_offset);
    printf("\n[%s DMA] CSR Status: 0x%08X\n", name, status);
    printf("  - Busy (Đang bận):           %d\n", (status & 1));
    printf("  - Desc Buffer Empty (Trống): %d\n", (status >> 1) & 1);
    printf("  - Desc Buffer Full (Đầy):    %d\n", (status >> 2) & 1);
    printf("  - Stop State (Bị ngắt):      %d\n", (status >> 5) & 1);
    printf("  - Stopped on Error (Lỗi):    %d\n", (status >> 7) & 1);
    printf("  - Early Termination:         %d\n", (status >> 8) & 1);
}

int main() {
    int fd;
    void *virtual_base_lw, *virtual_base_sdram;
    
    if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1) {
        printf("Lỗi: Không thể mở /dev/mem\n"); return 1;
    }

    virtual_base_lw = mmap(NULL, HW_REGS_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, HW_REGS_BASE);
    virtual_base_sdram = mmap(NULL, SDRAM_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, SDRAM_BASE);

    uint8_t *fpga_img_in  = (uint8_t *)(virtual_base_sdram + INPUT_OFFSET);
    uint8_t *fpga_img_out = (uint8_t *)(virtual_base_sdram + OUTPUT_OFFSET);

    int w, h, bpp;
    uint8_t *img_data = stbi_load("test_sobel_img.jpg", &w, &h, &bpp, 1);
    if (!img_data) {
        printf("Lỗi: Không tìm thấy ảnh test_sobel_img.jpg!\n"); return 1;
    }
    int img_size = w * h;

    for (int i = 0; i < img_size; i++) {
        fpga_img_in[i] = img_data[i];
        fpga_img_out[i] = 0;
    }

    printf("=======================================\n");
    printf("   SOBEL ACCELERATOR PROFILING TEST    \n");
    printf("=======================================\n");
    

    printf(">> Đang dọn dẹp và Reset DMA...\n");
    IOWR(virtual_base_lw, MSGDMA_WRITE_CSR + 0x04, (1 << 1)); // Ghi bit 1 vào thanh ghi Control
    IOWR(virtual_base_lw, MSGDMA_READ_CSR + 0x04, (1 << 1));
    usleep(1000); // Chờ 1ms cho phần cứng phản hồi

    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);


    uint32_t write_len = img_size - (2 * w); // Trừ 2 dòng Line Buffer
    IOWR(virtual_base_lw, MSGDMA_WRITE_DESC + 0x00, 0); // Read addr (Bỏ qua)
    IOWR(virtual_base_lw, MSGDMA_WRITE_DESC + 0x04, SDRAM_BASE + OUTPUT_OFFSET);
    IOWR(virtual_base_lw, MSGDMA_WRITE_DESC + 0x08, write_len);
    IOWR(virtual_base_lw, MSGDMA_WRITE_DESC + 0x0C, (1 << 31)); 

    IOWR(virtual_base_lw, MSGDMA_READ_DESC + 0x00, SDRAM_BASE + INPUT_OFFSET);
    IOWR(virtual_base_lw, MSGDMA_READ_DESC + 0x04, 0); // Write addr (Bỏ qua)
    IOWR(virtual_base_lw, MSGDMA_READ_DESC + 0x08, img_size);
    IOWR(virtual_base_lw, MSGDMA_READ_DESC + 0x0C, (1 << 31)); // Lệnh GO!


    printf(">> Hardware đang xử lý...\n");
    int timeout_ms = 2000; // Cấp thời gian tối đa 2 giây
    int time_elapsed = 0;
    
    // Theo dõi cờ BUSY (bit 0) của Write DMA
    while ((IORD(virtual_base_lw, MSGDMA_WRITE_CSR) & 1) != 0) {
        time_elapsed++;
        
        if (time_elapsed > timeout_ms) {
            printf("\n[!!! LỖI TIMEOUT] Hệ thống phần cứng bị kẹt cứng sau 2 giây!\n");
            printf("--- HỒ SƠ CHẨN ĐOÁN (CSR DUMP) ---");
            dump_dma_status(virtual_base_lw, "READ", MSGDMA_READ_CSR);
            dump_dma_status(virtual_base_lw, "WRITE", MSGDMA_WRITE_CSR);
            goto cleanup; 
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &end);
    double hw_time = (end.tv_sec - start.tv_sec) * 1000.0 + (end.tv_nsec - start.tv_nsec) / 1e6;
    printf("\n[THÀNH CÔNG] Thoi gian chay Hardware: %.3f ms\n", hw_time);

    stbi_write_png("output_sobel_hw.png", w, h, 1, fpga_img_out, w);
    printf("[OK] Đã lưu ảnh output_sobel_hw.png\n");

cleanup:
    stbi_image_free(img_data);
    munmap(virtual_base_lw, HW_REGS_SPAN);
    munmap(virtual_base_sdram, SDRAM_SPAN);
    close(fd);
    return 0;
}
