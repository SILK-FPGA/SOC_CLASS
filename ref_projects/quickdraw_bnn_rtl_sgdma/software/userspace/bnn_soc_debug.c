#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

// ========================================================
// 1. ĐỊA CHỈ HỆ THỐNG VÀ CẤU HÌNH
// ========================================================
#define LWHPS_BASE          0xFF200000
#define LWHPS_SPAN          0x1000

#define SDRAM_TARGET_ADDR   0x30000000
#define SDRAM_SPAN          0x4000

#define MSGDMA_CSR_OFFSET   0x0000
#define MSGDMA_DESC_OFFSET  0x0020
#define BNN_RESULT_OFFSET   0x0030

#define CSR_STATUS_REG      0x00
#define CSR_CONTROL_REG     0x04
#define DESC_READ_ADDR      0x00
#define DESC_WRITE_ADDR     0x04
#define DESC_LENGTH         0x08
#define DESC_CONTROL        0x0C

#define MSGDMA_CTRL_GEN_SOP_MASK  (1 << 8)
#define MSGDMA_CTRL_GEN_EOP_MASK  (1 << 9)
#define MSGDMA_CTRL_GO_MASK       (1 << 31)

const int expected_classes[10] = {2, 5, 1, 6, 1, 2, 8, 4, 4, 2};

// ========================================================
// 2. HÀM ĐIỀU KHIỂN DMA VÀ BẮT TAY ĐỒNG BỘ VỚI BNN
// ========================================================
uint32_t run_bnn_inference(volatile uint32_t *msgdma_csr_ptr, volatile uint32_t *msgdma_desc_ptr, volatile uint32_t *bnn_ptr, uint32_t transfer_length_bytes) {
    // 1. Reset mSGDMA
    *(msgdma_csr_ptr + (CSR_CONTROL_REG / 4)) = (1 << 1); 
    usleep(100);
    *(msgdma_csr_ptr + (CSR_CONTROL_REG / 4)) = 0x00;     

    // 2. Cấu hình Descriptor
    *(msgdma_desc_ptr + (DESC_READ_ADDR / 4))  = SDRAM_TARGET_ADDR;
    *(msgdma_desc_ptr + (DESC_WRITE_ADDR / 4)) = 0x00000000; 
    *(msgdma_desc_ptr + (DESC_LENGTH / 4))     = transfer_length_bytes;
    
    // 3. Kích hoạt DMA
    uint32_t desc_control = MSGDMA_CTRL_GO_MASK | MSGDMA_CTRL_GEN_SOP_MASK | MSGDMA_CTRL_GEN_EOP_MASK;
    *(msgdma_desc_ptr + (DESC_CONTROL / 4)) = desc_control;
    // KHÔNG CHỜ DMA NỮA! NGAY LẬP TỨC ĐỌC ĐIÊN CUỒNG VÀO THANH GHI BNN
    uint32_t bnn_val = 0;
    for(int i = 0; i < 5000000; i++) {
        bnn_val = *(bnn_ptr);
        if (bnn_val & (1U << 31)) {
            printf("    -> [THÀNH CÔNG] Đã chớp được cờ 20ns của BNN!\n");
            break;
        }
    }
    return bnn_val & 0x0F;
    

    // 5. [THAY ĐỔI] TIMEOUT POLLING thay vì vòng lặp vô tận
    
    int timeout = 5000; // Giới hạn 5000 vòng lặp 
    
    while (timeout > 0) {
        bnn_val = *(bnn_ptr);
        if (bnn_val & (1U << 31)) {
            break; // May mắn bắt được cờ
        }
        usleep(1); // Tránh chiếm dụng CPU 100%
        timeout--;
    }
    
    if (timeout == 0) {
        printf("    -> [CẢNH BÁO] Không bắt được Bit 31! Cưỡng ép đọc kết quả hiện tại...\n");
    }

    return bnn_val & 0x0F; // Bất chấp có bắt được cờ hay không, vẫn lấy 4 bit cuối
}

// ========================================================
// 3. HÀM MAIN
// ========================================================
int main() {
    int fd;
    void *virtual_base_lwhps;
    void *virtual_base_sdram;
    
    volatile uint32_t *msgdma_csr_ptr;
    volatile uint32_t *msgdma_desc_ptr;
    volatile uint32_t *bnn_ptr;
    volatile uint32_t *ram_ptr;

    if ((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        perror("FATAL: Không thể mở /dev/mem");
        return 1;
    }

    virtual_base_lwhps = mmap(NULL, LWHPS_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, LWHPS_BASE);
    virtual_base_sdram = mmap(NULL, SDRAM_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, SDRAM_TARGET_ADDR);

    msgdma_csr_ptr  = (uint32_t *)(virtual_base_lwhps + MSGDMA_CSR_OFFSET);
    msgdma_desc_ptr = (uint32_t *)(virtual_base_lwhps + MSGDMA_DESC_OFFSET);
    bnn_ptr         = (uint32_t *)(virtual_base_lwhps + BNN_RESULT_OFFSET);
    ram_ptr         = (uint32_t *)virtual_base_sdram;

    printf("====================================================\n");
    printf("[SYSTEM] STARTING WRAPPER AVALON HARDWARE EXECUTION\n");
    printf("====================================================\n");

    uint32_t transfer_length_bytes = 32 * 4; 
    char filename[32];

    for (int img_id = 0; img_id < 10; img_id++) {
        sprintf(filename, "test_img_%d.txt", img_id);
        
        FILE *fp = fopen(filename, "r");
        if (fp == NULL) {
            printf("[ERROR] Cannot open file %s\n", filename);
            continue;
        }

        // Xóa RAM trước khi nạp
        for (int k = 0; k < 32; k++) ram_ptr[k] = 0x00000000;

        uint32_t val;
        uint32_t packed_word = 0;
        int bit_idx = 0;
        int word_count = 0;
        
        // Đóng gói LSB-first theo đúng chuẩn SystemVerilog TB
        while (fscanf(fp, "%d", &val) == 1 && word_count < 32) { 
            if (val == 1) {
                packed_word |= (1U << bit_idx);
            }
            bit_idx++;
            
            if (bit_idx == 32) {
                ram_ptr[word_count] = packed_word;
                word_count++;
                packed_word = 0;
                bit_idx = 0; 
            }
        }
        fclose(fp);

        msync(virtual_base_sdram, transfer_length_bytes, MS_SYNC);

        printf("[INFO] Streaming Test Sample %d via Avalon-ST (Expected: %d)...\n", img_id, expected_classes[img_id]);
        printf("    -> Waiting for sys_valid & done_flag...\n");

        // Chạy Inference với Polling bit 31
        uint32_t res = run_bnn_inference(msgdma_csr_ptr, msgdma_desc_ptr, bnn_ptr, transfer_length_bytes);

        if (res == expected_classes[img_id]) {
            printf("    -> MATCH! Wrapper Predicted: %d\n", res);
        } else {
            printf("    -> FAIL! Expected: %d, Got: %d\n", expected_classes[img_id], res);
        }
    }

    munmap(virtual_base_lwhps, LWHPS_SPAN);
    munmap(virtual_base_sdram, SDRAM_SPAN);
    close(fd);

    printf("====================================================\n");
    printf("[SYSTEM] HARDWARE EXECUTION COMPLETED\n");
    printf("====================================================\n");

    return 0;
}
