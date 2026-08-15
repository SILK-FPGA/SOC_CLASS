#define _DEFAULT_SOURCE

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>

#define WIDTH                  32
#define HEIGHT                 32
#define PIXEL_COUNT            (WIDTH * HEIGHT)          /* 1024 pixels */
#define PACKED_RAW_SIZE        (PIXEL_COUNT / 8)         /* 128 bytes   */
#define AVALON_WORD_BYTES      32                        /* 256 bits    */
#define AVALON_WORDS           (PACKED_RAW_SIZE / AVALON_WORD_BYTES) /* 4 */

#define SDRAM_BASE_PHYS        0x30000000UL
#define SDRAM_MAP_SIZE         0x00100000UL

#define H2F_AXI_BASE_PHYS      0xC0000000UL
#define H2F_AXI_MAP_SIZE       0x00001000UL

#define CONNECT_PIO_OFFSET     0x00000000UL
#define AI_RESULT_PIO_OFFSET   0x00000010UL
#define AI_RESULT_TIMEOUT_MS   10000u

#define RESULT_VALID_MASK      (1u << 31)

/* Trả lại đúng 10 class của QuickDraw */
static const char *const class_names[10] = {
    "apple", "clock", "star", "bicycle", "cookie",
    "moon", "sword", "tree", "T-shirt", "lightning"
};

static int open_devmem(void)
{
    printf("[1] Opening /dev/mem...\n");

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        printf("ERROR: open /dev/mem failed: %s\n", strerror(errno));
        return -1;
    }

    printf("[1] /dev/mem OK\n");
    return fd;
}

/* 
 * Hàm đọc 1024 dòng từ file TXT và nén (pack) thành 128 byte LSB-first
 */
static int load_txt_image(const char *path, uint8_t packed[PACKED_RAW_SIZE])
{
    printf("[2] Opening TXT image file: %s\n", path);
    FILE *fp = fopen(path, "r");
    if (!fp) {
        printf("ERROR: cannot open '%s': %s\n", path, strerror(errno));
        return 1;
    }

    memset(packed, 0, PACKED_RAW_SIZE);
    int pixel_val;
    int count = 0;

    /* Đọc từng dòng, bỏ qua khoảng trắng/xuống dòng */
    while (count < PIXEL_COUNT && fscanf(fp, "%d", &pixel_val) == 1) {
        // Nếu giá trị pixel > 0, coi như đó là nét vẽ (logic 1)
        if (pixel_val > 0) {
            packed[count >> 3] |= (uint8_t)(1u << (count & 7));
        }
        count++;
    }
    fclose(fp);

    if (count != PIXEL_COUNT) {
        printf("ERROR: File doc thieu pixel! Chi thay %d/%d pixel.\n", count, PIXEL_COUNT);
        return 1;
    }

    printf("[2] Successfully parsed 1024 lines and packed to 128 bytes.\n");
    return 0;
}

static void print_ascii_preview(const uint8_t packed[PACKED_RAW_SIZE])
{
    printf("[3] 32x32 packed image preview (#=1, .=0):\n");

    for (int y = 0; y < HEIGHT; ++y) {
        printf("    ");
        for (int x = 0; x < WIDTH; ++x) {
            int pixel_index = y * WIDTH + x;
            int bit_value = (packed[pixel_index >> 3] >> (pixel_index & 7)) & 1u;
            putchar(bit_value ? '#' : '.');
        }
        putchar('\n');
    }
}

static int write_image_to_sdram(int mem_fd, const uint8_t packed[PACKED_RAW_SIZE])
{
    printf("[4] Mapping SDRAM at physical 0x%08lX...\n", SDRAM_BASE_PHYS);

    void *sdram_map = mmap(NULL, SDRAM_MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, SDRAM_BASE_PHYS);
    if (sdram_map == MAP_FAILED) {
        printf("ERROR: mmap SDRAM failed: %s\n", strerror(errno));
        return 1;
    }

    volatile uint8_t *sdram = (volatile uint8_t *)sdram_map;

    printf("[5] Writing %d packed bytes to SDRAM...\n", PACKED_RAW_SIZE);
    for (int i = 0; i < PACKED_RAW_SIZE; ++i) {
        sdram[i] = packed[i];
    }
    __sync_synchronize();

    if (msync(sdram_map, SDRAM_MAP_SIZE, MS_SYNC) != 0) {
        printf("WARNING: msync failed: %s\n", strerror(errno));
    }

    int mismatch_count = 0;
    for (int i = 0; i < PACKED_RAW_SIZE; ++i) {
        if (sdram[i] != packed[i]) {
            ++mismatch_count;
        }
    }

    if (mismatch_count != 0) {
        printf("ERROR: SDRAM verification failed!\n");
        munmap(sdram_map, SDRAM_MAP_SIZE);
        return 1;
    }

    printf("[6] SDRAM verification PASSED\n");
    munmap(sdram_map, SDRAM_MAP_SIZE);
    return 0;
}

static void print_ai_result_word(uint32_t word)
{
    unsigned valid  = (word >> 31) & 1u;
    unsigned busy   = (word >> 30) & 1u;
    unsigned stream = (word >> 29) & 1u;
    unsigned buffer = (word >> 28) & 1u;
    unsigned seq    = (word >> 16) & 0xFFu;
    unsigned cls    = word & 0xFu;

    printf("\n");
    printf("+==========================================================+\n");
    printf("|                 FPGA AI CLASSIFICATION                   |\n");
    printf("+==========================================================+\n");

    // Sửa lại thành kiểm tra dưới 10 class
    if (valid && cls < 10u) { 
        printf("|   CLASS ID     : %-2u                                      |\n", cls);
        printf("|   CLASS NAME   : %-12s                              |\n", class_names[cls]);
        printf("+----------------------------------------------------------+\n");
        printf("|   Result word  : 0x%08X                              |\n", word);
        printf("|   Sequence     : %-3u                                     |\n", seq);
        printf("|   Valid        : %-1u                                       |\n", valid);
        printf("|   Busy         : %-1u                                       |\n", busy);
        printf("|   Stream done  : %-1u                                       |\n", stream);
        printf("|   Buffer done  : %-1u                                       |\n", buffer);
    } else {
        printf("|               RESULT IS NOT VALID OR UNKNOWN             |\n");
        printf("|   Result word  : 0x%08X                              |\n", word);
    }
    printf("+==========================================================+\n\n");
}

static int trigger_and_wait_result(int mem_fd)
{
    printf("[7] Mapping H2F bridge at physical 0x%08lX...\n", H2F_AXI_BASE_PHYS);

    void *bridge_map = mmap(NULL, H2F_AXI_MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, H2F_AXI_BASE_PHYS);
    if (bridge_map == MAP_FAILED) {
        printf("ERROR: mmap H2F bridge failed: %s\n", strerror(errno));
        return 1;
    }

    volatile uint8_t *bridge_bytes = (volatile uint8_t *)bridge_map;
    volatile uint32_t *connect_pio = (volatile uint32_t *)(bridge_bytes + CONNECT_PIO_OFFSET);
    volatile uint32_t *result_pio = (volatile uint32_t *)(bridge_bytes + AI_RESULT_PIO_OFFSET);

    uint32_t old_result = *result_pio;
    unsigned old_seq = (old_result >> 16) & 0xFFu;

    *connect_pio = 0u;
    __sync_synchronize();
    usleep(10000);

    *connect_pio = 1u;
    __sync_synchronize();
    printf("[8] TRIGGER HIGH. Waiting for AI result (Timeout: %u ms)...\n", AI_RESULT_TIMEOUT_MS);

    uint32_t result = 0u;
    unsigned elapsed_ms = 0u;
    int got_new_result = 0;

    while (elapsed_ms < AI_RESULT_TIMEOUT_MS) {
        result = *result_pio;
        unsigned valid = (result >> 31) & 1u;
        unsigned seq = (result >> 16) & 0xFFu;

        if (valid && seq != old_seq) {
            got_new_result = 1;
            break;
        }

        usleep(1000);
        ++elapsed_ms;
    }

    *connect_pio = 0u;
    __sync_synchronize();
    printf("[8] TRIGGER LOW\n");

    if (!got_new_result) {
        printf("ERROR: timeout waiting for AI result\n");
        munmap(bridge_map, H2F_AXI_MAP_SIZE);
        return 1;
    }

    print_ai_result_word(result);
    munmap(bridge_map, H2F_AXI_MAP_SIZE);
    return 0;
}

int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);

    if (argc != 2) {
        printf("Usage: %s <image_32x32.txt>\n", argv[0]);
        return 1;
    }

    printf("=== BNN DMA TESTER (QUICKDRAW) ===\n");
    
    uint8_t packed[PACKED_RAW_SIZE];
    int ret = load_txt_image(argv[1], packed);
    if (ret != 0) return ret;

    print_ascii_preview(packed);

    int mem_fd = open_devmem();
    if (mem_fd < 0) return 1;

    ret = write_image_to_sdram(mem_fd, packed);
    if (ret == 0) {
        ret = trigger_and_wait_result(mem_fd);
    }

    close(mem_fd);
    return ret;
}

