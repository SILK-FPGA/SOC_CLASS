#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Hàm này cố tình để ở dạng thô sơ nhất để gprof dễ dàng bắt lỗi "ngốn thời gian"
void apply_sobel(unsigned char *input_gray, unsigned char *output_img, int width, int height) {
    int Gx[3][3] = {{-1, 0, 1}, {-2, 0, 2}, {-1, 0, 1}};
    int Gy[3][3] = {{-1, -2, -1}, {0, 0, 0}, {1, 2, 1}};

    // Bỏ qua viền ảnh (pixel ngoài cùng) để code đơn giản, không cần check boundary
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            int sumX = 0;
            int sumY = 0;

            // Quét ma trận 3x3
            for (int i = -1; i <= 1; i++) {
                for (int j = -1; j <= 1; j++) {
                    int pixel_val = input_gray[(y + i) * width + (x + j)];
                    sumX += pixel_val * Gx[i + 1][j + 1];
                    sumY += pixel_val * Gy[i + 1][j + 1];
                }
            }

            int magnitude = abs(sumX) + abs(sumY); // Dùng abs thay vì sqrt(x^2 + y^2) cho phần cứng dễ thở sau này
            if (magnitude > 255) magnitude = 255;
            if (magnitude < 0) magnitude = 0;

            output_img[y * width + x] = (unsigned char)magnitude;
        }
    }
}

int main(int argc, char **argv) {
    if (argc < 2) {
        printf("Usage: %s <input_image>\n", argv[0]);
        return -1;
    }

    int width, height, channels;
    // Đọc ảnh, ép về 3 channels (RGB)
    unsigned char *img = stbi_load(argv[1], &width, &height, &channels, 3);
    if (img == NULL) {
        printf("Loi doc anh!\n");
        return -1;
    }

    // Cấp phát bộ nhớ cho ảnh xám và ảnh kết quả
    unsigned char *gray_img = malloc(width * height);
    unsigned char *output_img = calloc(width * height, 1);

    // Chuyển RGB sang Grayscale
    for (int i = 0; i < width * height; i++) {
        int r = img[i * 3];
        int g = img[i * 3 + 1];
        int b = img[i * 3 + 2];
        gray_img[i] = (unsigned char)(0.299 * r + 0.587 * g + 0.114 * b);
    }

    // GỌI HÀM CẦN PROFILING
    printf("Bat dau chay Sobel Filter...\n");
    apply_sobel(gray_img, output_img, width, height);
    printf("Hoan thanh!\n");

    // Lưu file kết quả
    stbi_write_png("output_sobel.png", width, height, 1, output_img, width);

    // Dọn dẹp
    stbi_image_free(img);
    free(gray_img);
    free(output_img);

    return 0;
}
