import os
import sys

BIN_FILE = "class7_tree.bin"
TXT_OUTPUT = "class7_tree.txt"

if not os.path.exists(BIN_FILE):
    print(f"[ERROR] Không tìm thấy file {BIN_FILE} trong thư mục!")
    sys.exit(1)

with open(BIN_FILE, "rb") as f:
    raw_data = f.read()

total_bytes = len(raw_data)
print(f"[INFO] Đã đọc {BIN_FILE} - Kích thước: {total_bytes} bytes")

pixels = []

# --- KỊCH BẢN 1: File nhị phân dạng 1 Byte / Pixel (1024 bytes -> 32x32) ---
if total_bytes == 1024:
    print("[DETECT] Format: 1 Byte/Pixel (1024 bytes)")
    pixels = [1 if b > 0 else 0 for b in raw_data]

# --- KỊCH BẢN 2: File nhị phân đén nén 1 Bit / Pixel (128 bytes -> 1024 bits -> 32x32) ---
elif total_bytes == 128:
    print("[DETECT] Format: 1 Bit/Pixel (128 bytes = 1024 bits)")
    for b in raw_data:
        # Tách từng bit trong byte (MSB first hoặc LSB first)
        for bit_idx in range(8):
            pixel = (b >> (7 - bit_idx)) & 1
            pixels.append(pixel)

# --- KỊCH BẢN 3: Kích thước khác -> Đọc toàn bộ thành các bit ---
else:
    print(
        f"[WARNING] Kích thước file ({total_bytes} bytes) không chuẩn 128/1024 bytes!"
    )
    print("-> Tự động đọc theo dạng mảng byte pixel (>=1 = pixel trắng)...")
    pixels = [1 if b > 0 else 0 for b in raw_data]

# Giới hạn hoặc Pad đủ 1024 pixels (32x32)
if len(pixels) < 1024:
    pixels.extend([0] * (1024 - len(pixels)))
elif len(pixels) > 1024:
    pixels = pixels[:1024]

# --- 1. XUẤT OUT FILE TEXT CHO FPGA ---
with open(TXT_OUTPUT, "w") as f:
    for p in pixels:
        f.write(f"{p}\n")

print(f"[SUCCESS] Đã chuyển đổi thành công sang file: {TXT_OUTPUT}")

# --- 2. VẼ ẢNH TRỰC QUAN TRÊN TERMINAL ---
print("\n====================================================")
printf_title = f"ẢNH TỪ FILE {BIN_FILE} (Góc nhìn 32x32)"
print(printf_title)
print("====================================================")

for r in range(32):
    row_str = ""
    for c in range(32):
        p = pixels[r * 32 + c]
        row_str += "██" if p == 1 else "  "
    print(row_str + "|")

print("====================================================\n")
