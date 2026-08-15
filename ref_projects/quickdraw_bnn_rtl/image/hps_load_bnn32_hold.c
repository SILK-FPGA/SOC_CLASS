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
#define GRAY_RAW_SIZE          PIXEL_COUNT               /* 1024 bytes  */
#define PACKED_RAW_SIZE        (PIXEL_COUNT / 8)         /* 128 bytes   */
#define AVALON_WORD_BYTES      32                        /* 256 bits    */
#define AVALON_WORDS           (PACKED_RAW_SIZE / AVALON_WORD_BYTES) /* 4 */

#define SDRAM_BASE_PHYS        0x30000000UL
#define SDRAM_MAP_SIZE         0x00100000UL

#define H2F_AXI_BASE_PHYS      0xC0000000UL
#define H2F_AXI_MAP_SIZE       0x00001000UL

#define CONNECT_HIGH_TIME_SEC  5

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

static long get_file_size(FILE *fp)
{
    if (fseek(fp, 0, SEEK_END) != 0) {
        return -1;
    }

    long size = ftell(fp);
    if (size < 0) {
        return -1;
    }

    if (fseek(fp, 0, SEEK_SET) != 0) {
        return -1;
    }

    return size;
}

/*
 * Packing order used by the FPGA buffer:
 *
 * packed[0] bit 0 = pixel 0   = (x=0,  y=0)
 * packed[0] bit 1 = pixel 1   = (x=1,  y=0)
 * ...
 * packed[3] bit 7 = pixel 31  = (x=31, y=0)
 * packed[4] bit 0 = pixel 32  = (x=0,  y=1)
 * ...
 * packed[127] bit 7 = pixel 1023 = (x=31, y=31)
 *
 * This matches:
 *   BYTE0_AT_LSB = 1
 *   BIT0_AT_LSB  = 1
 */
static void pack_32x32_lsb_first(const uint8_t *src,
                                 uint8_t *packed,
                                 uint8_t threshold,
                                 int dark_is_one,
                                 int source_is_binary)
{
    memset(packed, 0, PACKED_RAW_SIZE);

    for (int i = 0; i < PIXEL_COUNT; ++i) {
        int bit_value;

        if (source_is_binary) {
            /* A 1024-byte file containing only 0/1 is already logical. */
            bit_value = (src[i] != 0);
        } else if (dark_is_one) {
            bit_value = (src[i] < threshold);
        } else {
            bit_value = (src[i] >= threshold);
        }

        if (bit_value) {
            packed[i >> 3] |= (uint8_t)(1u << (i & 7));
        }
    }
}

static int input_is_unpacked_binary(const uint8_t *data)
{
    for (int i = 0; i < PIXEL_COUNT; ++i) {
        if (data[i] > 1u) {
            return 0;
        }
    }

    return 1;
}

static int load_and_prepare_image(const char *path,
                                  uint8_t packed[PACKED_RAW_SIZE],
                                  uint8_t threshold,
                                  int dark_is_one)
{
    printf("[2] Opening image file: %s\n", path);

    FILE *fp = fopen(path, "rb");
    if (!fp) {
        printf("ERROR: cannot open '%s': %s\n", path, strerror(errno));
        return 1;
    }

    long file_size = get_file_size(fp);
    if (file_size < 0) {
        printf("ERROR: cannot determine input file size\n");
        fclose(fp);
        return 1;
    }

    printf("[2] Input file size = %ld bytes\n", file_size);

    if (file_size == PACKED_RAW_SIZE) {
        /* Already packed: 1024 bits = 128 bytes. */
        size_t n = fread(packed, 1, PACKED_RAW_SIZE, fp);
        fclose(fp);

        if (n != PACKED_RAW_SIZE) {
            printf("ERROR: read packed image failed: got %zu bytes\n", n);
            return 1;
        }

        printf("[2] Format detected: packed 32x32, 1 bit/pixel\n");
        printf("[2] Threshold options are ignored for packed input\n");
        return 0;
    }

    if (file_size == GRAY_RAW_SIZE) {
        uint8_t raw[GRAY_RAW_SIZE];
        size_t n = fread(raw, 1, GRAY_RAW_SIZE, fp);
        fclose(fp);

        if (n != GRAY_RAW_SIZE) {
            printf("ERROR: read 32x32 input failed: got %zu bytes\n", n);
            return 1;
        }

        int source_is_binary = input_is_unpacked_binary(raw);

        if (source_is_binary) {
            printf("[2] Format detected: unpacked binary 32x32 (1024 bytes of 0/1)\n");
        } else {
            printf("[2] Format detected: grayscale 32x32, 8 bit/pixel\n");
            printf("[2] Threshold = %u, dark_is_one = %d\n",
                   (unsigned)threshold, dark_is_one);
        }

        pack_32x32_lsb_first(raw,
                             packed,
                             threshold,
                             dark_is_one,
                             source_is_binary);
        return 0;
    }

    printf("ERROR: unsupported input size %ld bytes\n", file_size);
    printf("Expected one of:\n");
    printf("  %d bytes: 32x32 grayscale or unpacked binary\n", GRAY_RAW_SIZE);
    printf("  %d bytes: packed 32x32, 1 bit/pixel\n", PACKED_RAW_SIZE);

    fclose(fp);
    return 1;
}

static void print_ascii_preview(const uint8_t packed[PACKED_RAW_SIZE])
{
    printf("[3] 32x32 packed image preview (#=1, .=0):\n");

    for (int y = 0; y < HEIGHT; ++y) {
        printf("    ");

        for (int x = 0; x < WIDTH; ++x) {
            int pixel_index = y * WIDTH + x;
            int bit_value =
                (packed[pixel_index >> 3] >> (pixel_index & 7)) & 1u;

            putchar(bit_value ? '#' : '.');
        }

        putchar('\n');
    }
}

static void print_avalon_words(const uint8_t packed[PACKED_RAW_SIZE])
{
    printf("[4] Data to be written: %d Avalon words x 256 bits\n", AVALON_WORDS);

    for (int word = 0; word < AVALON_WORDS; ++word) {
        printf("    word[%d], SDRAM + 0x%03X:\n        ",
               word,
               word * AVALON_WORD_BYTES);

        /* Print high byte first only for easier visual reading. */
        for (int byte = AVALON_WORD_BYTES - 1; byte >= 0; --byte) {
            int index = word * AVALON_WORD_BYTES + byte;
            printf("%02X", packed[index]);

            if ((byte & 3) == 0 && byte != 0) {
                putchar('_');
            }
        }

        putchar('\n');
    }
}

static int write_image_to_sdram(int mem_fd,
                                const uint8_t packed[PACKED_RAW_SIZE])
{
    printf("[5] Mapping SDRAM at physical 0x%08lX, size 0x%08lX...\n",
           SDRAM_BASE_PHYS, SDRAM_MAP_SIZE);

    void *sdram_map = mmap(NULL,
                           SDRAM_MAP_SIZE,
                           PROT_READ | PROT_WRITE,
                           MAP_SHARED,
                           mem_fd,
                           SDRAM_BASE_PHYS);

    if (sdram_map == MAP_FAILED) {
        printf("ERROR: mmap SDRAM failed: %s\n", strerror(errno));
        return 1;
    }

    printf("[5] SDRAM mmap OK\n");

    volatile uint8_t *sdram = (volatile uint8_t *)sdram_map;

    printf("[6] Writing %d packed bytes to SDRAM 0x%08lX...\n",
           PACKED_RAW_SIZE, SDRAM_BASE_PHYS);

    for (int i = 0; i < PACKED_RAW_SIZE; ++i) {
        sdram[i] = packed[i];
    }

    __sync_synchronize();

    if (msync(sdram_map, SDRAM_MAP_SIZE, MS_SYNC) != 0) {
        printf("WARNING: msync failed: %s\n", strerror(errno));
    }

    printf("[6] SDRAM write done\n");

    printf("[7] Verifying SDRAM read-back...\n");

    int mismatch_count = 0;
    for (int i = 0; i < PACKED_RAW_SIZE; ++i) {
        uint8_t actual = sdram[i];

        if (actual != packed[i]) {
            if (mismatch_count < 16) {
                printf("ERROR: offset 0x%03X: expected %02X, got %02X\n",
                       i, packed[i], actual);
            }
            ++mismatch_count;
        }
    }

    if (mismatch_count != 0) {
        printf("ERROR: SDRAM verification failed: %d mismatched bytes\n",
               mismatch_count);
        munmap(sdram_map, SDRAM_MAP_SIZE);
        return 1;
    }

    printf("[7] SDRAM verification PASSED (%d/%d bytes match)\n",
           PACKED_RAW_SIZE, PACKED_RAW_SIZE);

    printf("[7] First 32 SDRAM bytes:\n    ");
    for (int i = 0; i < AVALON_WORD_BYTES; ++i) {
        printf("%02X ", (unsigned)sdram[i]);
    }
    putchar('\n');

    if (munmap(sdram_map, SDRAM_MAP_SIZE) != 0) {
        printf("WARNING: munmap SDRAM failed: %s\n", strerror(errno));
    } else {
        printf("[8] SDRAM unmapped\n");
    }

    return 0;
}

static int pulse_connect(int mem_fd)
{
    printf("[9] Mapping full HPS-to-FPGA bridge at physical 0x%08lX...\n",
           H2F_AXI_BASE_PHYS);

    void *bridge_map = mmap(NULL,
                            H2F_AXI_MAP_SIZE,
                            PROT_READ | PROT_WRITE,
                            MAP_SHARED,
                            mem_fd,
                            H2F_AXI_BASE_PHYS);

    if (bridge_map == MAP_FAILED) {
        printf("ERROR: mmap H2F bridge failed: %s\n", strerror(errno));
        return 1;
    }

    printf("[9] Bridge mmap OK\n");
    printf("[9] PIO/connect physical address = 0x%08lX\n",
           H2F_AXI_BASE_PHYS);

    volatile uint32_t *pio = (volatile uint32_t *)bridge_map;

    printf("[10] CONNECT sequence: 0 -> 1 -> hold %d sec -> 0\n",
           CONNECT_HIGH_TIME_SEC);

    *pio = 0x00000000u;
    __sync_synchronize();
    usleep(10000);

    *pio = 0x00000001u;
    __sync_synchronize();

    printf("[10] CONNECT HIGH. FPGA should read 4 x 256-bit words.\n");
    sleep(CONNECT_HIGH_TIME_SEC);

    *pio = 0x00000000u;
    __sync_synchronize();

    printf("[10] CONNECT LOW\n");

    if (munmap(bridge_map, H2F_AXI_MAP_SIZE) != 0) {
        printf("WARNING: munmap bridge failed: %s\n", strerror(errno));
    } else {
        printf("[11] Bridge unmapped\n");
    }

    return 0;
}

static int parse_u8(const char *text, uint8_t *value)
{
    char *end = NULL;
    errno = 0;

    unsigned long parsed = strtoul(text, &end, 0);

    if (errno != 0 || end == text || *end != '\0' || parsed > 255u) {
        return 1;
    }

    *value = (uint8_t)parsed;
    return 0;
}

static int parse_bool01(const char *text, int *value)
{
    if (strcmp(text, "0") == 0) {
        *value = 0;
        return 0;
    }

    if (strcmp(text, "1") == 0) {
        *value = 1;
        return 0;
    }

    return 1;
}

static void print_usage(const char *program)
{
    printf("Usage:\n");
    printf("  %s image.raw [threshold] [dark_is_one]\n", program);
    printf("\n");
    printf("Accepted input formats:\n");
    printf("  1024 bytes : 32x32 grayscale or one byte per binary pixel\n");
    printf("   128 bytes : already packed 32x32, one bit per pixel\n");
    printf("\n");
    printf("Defaults for 1024-byte grayscale input:\n");
    printf("  threshold   = 128\n");
    printf("  dark_is_one = 0  (bright/white pixels become 1)\n");
    printf("\n");
    printf("Examples:\n");
    printf("  %s image_32x32.raw\n", program);
    printf("  %s image_32x32.raw 128 0\n", program);
    printf("  %s black_on_white_32x32.raw 128 1\n", program);
    printf("  %s image_32x32_packed.bin\n", program);
}

int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);

    uint8_t threshold = 128u;
    int dark_is_one = 0;

    if (argc < 2 || argc > 4) {
        print_usage(argv[0]);
        return 1;
    }

    if (argc >= 3 && parse_u8(argv[2], &threshold) != 0) {
        printf("ERROR: threshold must be an integer from 0 to 255\n");
        return 1;
    }

    if (argc >= 4 && parse_bool01(argv[3], &dark_is_one) != 0) {
        printf("ERROR: dark_is_one must be 0 or 1\n");
        return 1;
    }

    printf("=== HPS LOAD BNN IMAGE 32x32 TO SDRAM + CONNECT HOLD ===\n");
    printf("SDRAM image base : 0x%08lX\n", SDRAM_BASE_PHYS);
    printf("Image dimensions : %d x %d\n", WIDTH, HEIGHT);
    printf("Packed size      : %d bytes = %d bits\n",
           PACKED_RAW_SIZE, PIXEL_COUNT);
    printf("Avalon transfer  : %d words x 256 bits\n", AVALON_WORDS);
    printf("Bit order        : pixel 0 is byte 0, bit 0 (LSB first)\n");
    printf("Full H2F AXI base: 0x%08lX\n", H2F_AXI_BASE_PHYS);
    printf("Connect high time: %d seconds\n", CONNECT_HIGH_TIME_SEC);

    uint8_t packed[PACKED_RAW_SIZE];

    int ret = load_and_prepare_image(argv[1],
                                     packed,
                                     threshold,
                                     dark_is_one);
    if (ret != 0) {
        return ret;
    }

    print_ascii_preview(packed);
    print_avalon_words(packed);

    int mem_fd = open_devmem();
    if (mem_fd < 0) {
        return 1;
    }

    ret = write_image_to_sdram(mem_fd, packed);

    if (ret == 0) {
        ret = pulse_connect(mem_fd);
    } else {
        printf("Skip CONNECT because SDRAM write/verification failed.\n");
    }

    close(mem_fd);

    printf("DONE, ret=%d\n", ret);
    return ret;
}
