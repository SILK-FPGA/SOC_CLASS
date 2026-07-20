TARGET = full_adder
CROSS_COMPILE ?= arm-linux-gnueabihf-
CC = $(CROSS_COMPILE)gcc

CFLAGS = -g -Wall -std=gnu99
# Quan trọng: Thêm -static vào LDFLAGS để ép Linker gộp mọi thư viện vào file thực thi
LDFLAGS = -g -Wall -static

build: $(TARGET)

$(TARGET): $(TARGET).o
	$(CC) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(TARGET) *.a *.o *.~
