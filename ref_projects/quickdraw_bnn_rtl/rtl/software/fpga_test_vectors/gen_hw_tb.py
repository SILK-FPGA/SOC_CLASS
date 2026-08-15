import os

def generate_sv(img_file, meta_file, output_sv):
    print("====================================================")
    print(f"[*] Đang đóng gói dữ liệu từ {img_file} và {meta_file}...")
    
    # ---------------------------------------------------------
    # 1. MÓC GIÁ TRỊ NHÃN (CLASS) TỪ META FILE (ĐÃ BỎ RR)
    # ---------------------------------------------------------
    try:
        with open(meta_file, 'r') as f:
            # Lấy các dòng không bị trống
            lines = [l.strip() for l in f if l.strip()]
            # Lấy giá trị nhãn từ file meta (ví dụ: '2')[cite: 12]
            exp_class = lines[0].split()[-1]
    except Exception as e:
        print(f"[LỖI] Đọc file meta thất bại: {e}")
        return

    # ---------------------------------------------------------
    # 2. MÓC ĐÚNG 1024 BIT TỪ IMAGE FILE
    # ---------------------------------------------------------
    try:
        with open(img_file, 'r') as f:
            # Vét tất cả các số '0' và '1' trong file, gom thành một list[cite: 13, 14]
            img_bits = [char for line in f for char in line.strip() if char in ['0', '1']]
    except Exception as e:
        print(f"[LỖI] Đọc file ảnh thất bại: {e}")
        return

    if len(img_bits) != 1024:
        print(f"[CẢNH BÁO] Hệ thống đếm được {len(img_bits)} bit thay vì 1024 bit. Kiểm tra lại file ảnh!")

    # ---------------------------------------------------------
    # 3. KẾT XUẤT RA SYSTEMVERILOG
    # ---------------------------------------------------------
    try:
        with open(output_sv, 'w') as f:
            f.write("package hw_stimulus;\n")
            f.write(f"    localparam logic [3:0] TEST_EXPECTED_CLASS = 4'd{exp_class};\n")
            f.write("    // Mảng 1024 bit chứa ảnh 32x32\n")
            f.write("    localparam logic TEST_IMG [0:1023] = '{\n")

            # Ghi từng bit một, thêm dấu phẩy[cite: 14]
            for i, bit in enumerate(img_bits):
                if i < len(img_bits) - 1:
                    # Các bit từ 0 đến 1022: Có dấu phẩy[cite: 14]
                    f.write(f"        1'b{bit},\n")
                else:
                    # Bit thứ 1023 (Cuối cùng): KHÔNG có dấu phẩy[cite: 14]
                    f.write(f"        1'b{bit}\n") 

            f.write("    };\n")
            f.write("endpackage\n")
            
        print(f"[THÀNH CÔNG] Đã sinh file {output_sv} chuẩn mảng. Sẵn sàng cho Quartus!")
        print("====================================================")
    except Exception as e:
        print(f"[LỖI] Quá trình ghi file SV thất bại: {e}")

if __name__ == "__main__":
    # Đảm bảo 2 file test_img_1.txt và test_meta_1.txt nằm chung thư mục với script này
    generate_sv('test_img_live.txt', 'test_meta_live.txt', 'hw_stimulus.sv')
