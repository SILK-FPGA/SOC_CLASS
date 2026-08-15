import glob
import os
import re


def render_image(file_path):
    with open(file_path, "r") as f:
        pixels = [line.strip() for line in f if line.strip() in ["0", "1"]]

    print("=" * 52)
    print(
        f"FILE: {os.path.basename(file_path)} (Total pixels: {len(pixels)})"
    )
    print("=" * 52)

    # Nếu file là 784 pixels (28x28)
    if len(pixels) == 784:
        for r in range(28):
            row_str = "".join(
                "██" if pixels[r * 28 + c] == "1" else "  " for c in range(28)
            )
            print(row_str + "|")

    # Nếu file là 1024 pixels (32x32)
    elif len(pixels) == 1024:
        for r in range(32):
            row_str = "".join(
                "██" if pixels[r * 32 + c] == "1" else "  " for c in range(32)
            )
            print(row_str + "|")

    else:
        print(f"[WARNING] Số lượng pixel ({len(pixels)}) không chuẩn!")

    print("-" * 52 + "\n")


if __name__ == "__main__":
    # Tìm file test_img_*.txt và sắp xếp theo số
    img_files = glob.glob("test_img_*.txt")

    def extract_number(filename):
        match = re.search(r"\d+", filename)
        return int(match.group()) if match else 999

    img_files = sorted(img_files, key=extract_number)

    if not img_files:
        print("[ERROR] Không tìm thấy file test_img_*.txt nào!")
    else:
        for img_path in img_files:
            render_image(img_path)
