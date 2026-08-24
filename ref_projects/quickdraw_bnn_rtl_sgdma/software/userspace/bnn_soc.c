#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

// ========================================================
// 1. ĐỊA CHỈ HỆ THỐNG TRÊN DE10-NANO
// ========================================================
#define LWHPS_BASE          0xFF200000
#define LWHPS_SPAN          0x1000
#define SDRAM_TARGET_ADDR   0x30000000
#define SDRAM_SPAN          0x4000

#define MSGDMA_CSR_OFFSET   0x0000 
#define BNN_WRAPPER_OFFSET  0x0020 
#define MSGDMA_DESC_OFFSET  0x0040 

#define DMA_CSR_CONTROL     1
#define DMA_DESC_READ_ADDR  0
#define DMA_DESC_WRITE_ADDR 1
#define DMA_DESC_LENGTH     2
#define DMA_DESC_CONTROL    3

#define BNN_REG_RESULT      0 
#define BNN_REG_SOFT_RESET  5 

// --- CÔNG TẮC ĐỒNG BỘ ENDIANNESS ---
#define ENABLE_AXI_BYTE_SWAP 1  
#define ENABLE_MSB_FIRST     0  

// ========================================================
// 2. HÀM ĐIỀU KHIỂN PHẦN CỨNG
// ========================================================
uint32_t run_bnn_inference(volatile uint32_t *msgdma_csr, volatile uint32_t *msgdma_desc, volatile uint32_t *bnn_csr) {
    msgdma_csr[DMA_CSR_CONTROL] = (1 << 1); 
    bnn_csr[BNN_REG_SOFT_RESET] = 1;
    usleep(50); 

    msgdma_desc[DMA_DESC_READ_ADDR]  = SDRAM_TARGET_ADDR;
    msgdma_desc[DMA_DESC_WRITE_ADDR] = 0; 
    msgdma_desc[DMA_DESC_LENGTH]     = 128; 
    msgdma_desc[DMA_DESC_CONTROL]    = (1 << 31) | (1 << 8) | (1 << 9);
    
    int timeout = 50000; 
    uint32_t bnn_val = 0;
    while (timeout > 0) {
        bnn_val = bnn_csr[BNN_REG_RESULT];
        if (bnn_val & (1U << 31)) { 
            bnn_csr[BNN_REG_RESULT] = (1U << 31); 
            return bnn_val & 0x0F; 
        }
        usleep(1); 
        timeout--;
    }
    return 0xFF; // Timeout
}

// ========================================================
// 3. MAIN PROGRAM
// ========================================================
int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("[LỖI] Thiếu tên file ảnh!\n");
        printf("Sử dụng: %s <file_anh.txt>\n", argv[0]);
        return 1;
    }

    char *filename = argv[1];
    FILE *fp = fopen(filename, "r");
    if (fp == NULL) {
        printf("[LỖI] Không thể mở file %s\n", filename);
        return 1;
    }

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd == -1) {
        perror("FATAL: Không thể mở /dev/mem. Cần chạy quyền root (sudo)?");
        return 1;
    }

    void *virtual_base_lwhps = mmap(NULL, LWHPS_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, LWHPS_BASE);
    void *virtual_base_sdram = mmap(NULL, SDRAM_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, SDRAM_TARGET_ADDR);

    volatile uint32_t *msgdma_csr  = (uint32_t *)(virtual_base_lwhps + MSGDMA_CSR_OFFSET);
    volatile uint32_t *bnn_csr     = (uint32_t *)(virtual_base_lwhps + BNN_WRAPPER_OFFSET);
    volatile uint32_t *msgdma_desc = (uint32_t *)(virtual_base_lwhps + MSGDMA_DESC_OFFSET);
    volatile uint32_t *ram_ptr     = (uint32_t *)virtual_base_sdram;

    // --- 1. DỌN BỘ ĐỆM RAM ---
    for (int k = 0; k < 32; k++) ram_ptr[k] = 0x00000000;

    // --- 2. ĐỌC FILE VÀ ĐÓNG GÓI PIXEL ---
    int val, row = 0, col = 0;
    uint32_t packed_word = 0;

    while (fscanf(fp, "%d", &val) == 1) { 
        if (val == 1) {
            #if ENABLE_MSB_FIRST
                packed_word |= (1U << (31 - col));
            #else
                packed_word |= (1U << col);
            #endif
        }
        col++;
        
        if (col == 32) {
            #if ENABLE_AXI_BYTE_SWAP
                packed_word = __builtin_bswap32(packed_word);
            #endif
            ram_ptr[row++] = packed_word; 
            col = 0;
            packed_word = 0;
            if (row == 32) break; 
        }
    }
    fclose(fp);
    msync(virtual_base_sdram, 128, MS_SYNC); 

    // --- 3. HIỂN THỊ X-QUANG TRỰC QUAN ---
    printf("\n========================================\n");
    printf(" FILE: %s\n", filename);
    printf("========================================\n");
    for (int r = 0; r < 32; r++) {
        uint32_t display_word = ram_ptr[r];
        
        #if ENABLE_AXI_BYTE_SWAP
            display_word = __builtin_bswap32(display_word);
        #endif
        
        for (int c = 0; c < 32; c++) {
            int bit_idx = ENABLE_MSB_FIRST ? (31 - c) : c;
            int pixel = (display_word >> bit_idx) & 1;
            printf("%s", pixel ? "██" : "  "); 
        }
        printf("|\n");
    }
    printf("========================================\n");

    // --- 4. GỌI BNN TĂNG TỐC PHẦN CỨNG ---
    printf("[INFO] Đang xử lý qua bộ gia tốc FPGA...\n");
    uint32_t res = run_bnn_inference(msgdma_csr, msgdma_desc, bnn_csr);
    
    if (res == 0xFF) {
        printf("    => [LỖI] Hệ thống BNN không phản hồi!\n");
    } else {
        printf("    => KẾT QUẢ PHÂN LOẠI (CLASS): %d\n", res);
    }
    printf("\n");

    munmap(virtual_base_lwhps, LWHPS_SPAN);
    munmap(virtual_base_sdram, SDRAM_SPAN);
    close(fd);
    
    return 0;
}

