import os
import re
import torch
import numpy as np
import torch.nn as nn
import torch.nn.functional as F

# ==========================================
# 1. ĐỊNH NGHĨA MẠNG DÀNH CHO QUICK DRAW!
# ==========================================
class BinaryActivation01(torch.autograd.Function):
    @staticmethod
    def forward(ctx, input):
        ctx.save_for_backward(input)
        return torch.where(input > 0, torch.ones_like(input), torch.zeros_like(input))

    @staticmethod
    def backward(ctx, grad_output):
        input, = ctx.saved_tensors
        grad_input = grad_output.clone()
        grad_input[input.abs() > 1] = 0
        return grad_input

def binary_step(x):
    return BinaryActivation01.apply(x)

class QAT_Conv2d(nn.Conv2d):
    def forward(self, input):
        w_bin = torch.where(self.weight > 0, torch.ones_like(self.weight), torch.zeros_like(self.weight))
        w_ste = self.weight + (w_bin - self.weight).detach()
        return F.conv2d(input, w_ste, self.bias, self.stride, self.padding, self.dilation, self.groups)

class QAT_Linear(nn.Linear):
    def forward(self, input):
        w_bin = torch.where(self.weight > 0, torch.ones_like(self.weight), torch.zeros_like(self.weight))
        w_ste = self.weight + (w_bin - self.weight).detach()
        return F.linear(input, w_ste, self.bias)

class bDSCNN(nn.Module):
    def __init__(self):
        super(bDSCNN, self).__init__()
        self.mcp = QAT_Conv2d(1, 3, kernel_size=4, stride=2, padding=0, bias=False)
        self.bn_mcp = nn.BatchNorm2d(3)
        self.dw = QAT_Conv2d(3, 3, kernel_size=3, stride=1, padding=0, groups=3, bias=False)
        self.pw = QAT_Conv2d(3, 18, kernel_size=1, stride=1, padding=0, bias=False)
        self.bn_pw = nn.BatchNorm2d(18)
        
        self.fc1 = QAT_Linear(3042, 64, bias=False)
        self.bn_fc1 = nn.BatchNorm1d(64)
        
        self.fc2 = QAT_Linear(64, 10, bias=False)
        self.bn_fc2 = nn.BatchNorm1d(10)

    def forward(self, img): 
        x = self.mcp(img)
        x = binary_step(self.bn_mcp(x)) 
        x = self.dw(x) 
        x = self.pw(x)
        x = binary_step(self.bn_pw(x)) 
        x = x.view(x.size(0), -1) 
        x = self.fc1(x)
        x = binary_step(self.bn_fc1(x)) 
        x = self.fc2(x)
        x = self.bn_fc2(x) 
        return x

# ==========================================
# 2. HÀM TRÍCH XUẤT DỮ LIỆU TỪ FILE .MIF
# ==========================================
def parse_mif_stimulus(mif_file_path):
    with open(mif_file_path, 'r') as f:
        content = f.readlines()

    img_bits = []
    started = False
    for line in content:
        if "CONTENT BEGIN" in line:
            started = True
            continue
        if started:
            if "END;" in line:
                break
            # Tìm pattern dạng "0 : 1;"
            match = re.search(r'\d+\s*:\s*([01]);', line)
            if match:
                img_bits.append(match.group(1))

    if len(img_bits) != 1024:
        raise ValueError(f"Đếm sai số lượng bit! Tìm thấy {len(img_bits)} bits thay vì 1024.")

    img_array = np.array([float(b) for b in img_bits], dtype=np.float32).reshape(1, 1, 32, 32)
    img_tensor = torch.tensor(img_array)

    return img_tensor
    
def visualize_img_tensor(img_tensor):
    img_np = img_tensor.squeeze().numpy()
    
    print("\n[VISUALIZATION] BỨC ẢNH PYTHON ĐANG NHÌN THẤY:")
    print("-" * 34)
    for row in range(32):
        row_str = ""
        for col in range(32):
            row_str += "█" if img_np[row, col] > 0.5 else "."
        print("|" + row_str + "|")
    print("-" * 34)

# ==========================================
# 3. THỰC THI KIỂM CHỨNG (GOLDEN RUN)
# ==========================================
if __name__ == "__main__":
    print("====================================================")
    print("[SYSTEM] KHỞI ĐỘNG QUICK DRAW! GOLDEN MODEL VERIFICATION")
    print("====================================================")

    # ĐỌC FILE LIVE_IMAGE.MIF THAY VÌ HW_STIMULUS.SV
    mif_file = "live_image.mif"
    try:
        img_t = parse_mif_stimulus(mif_file)
        visualize_img_tensor(img_t)
        print(f"[INFO] Lấy dữ liệu thành công từ: {mif_file}")
        print(f"[INFO] Image Shape: {img_t.shape}")
    except Exception as e:
        print(f"[ERROR] {e}")
        exit()

    model = bDSCNN()
    weight_file = "best_qat_quickdraw_model.pth"
    
    if os.path.exists(weight_file):
        model.load_state_dict(torch.load(weight_file, map_location='cpu'))
        print(f"[INFO] Đã nạp thành công weights từ: {weight_file}")
    else:
        print(f"[WARNING] Không tìm thấy '{weight_file}'. Đang chạy với weights khởi tạo ngẫu nhiên!")

    model.eval()
    with torch.no_grad():
        for name, module in model.named_modules():
            if isinstance(module, (nn.Conv2d, nn.Linear)):
                binary_w = torch.where(module.weight.data > 0, 
                                       torch.ones_like(module.weight.data), 
                                       torch.zeros_like(module.weight.data))
                module.weight.copy_(binary_w)
                
        output = model(img_t)
        
        top5_scores, top5_indices = torch.topk(output, k=5, dim=1)
        
        raw_scores = output.tolist()[0]
        top5_s = top5_scores.tolist()[0]
        top5_i = top5_indices.tolist()[0]
        
        pred_class = top5_i[0] 
        
    class_map = ['apple', 'clock', 'star', 'bicycle', 'cookie', 
                 'moon', 'sword', 'tree', 't-shirt', 'lightning']
        
    print("\n====================================================")
    print(f"🧠 KẾT QUẢ ĐIỂM SỐ TỔNG (RAW LUT SCORES):")
    print(f"{raw_scores}")
    
    print("\n🏆 BẢNG XẾP HẠNG TOP-5 DỰ ĐOÁN TỪ PYTHON:")
    for i in range(5):
        c_idx = top5_i[i]
        c_score = top5_s[i]
        c_name = class_map[c_idx].upper()
        print(f"   {i+1}. {c_name:<10} | Class {c_idx} | Điểm: {c_score:.4f}")
        
    print("====================================================")
    print(f"\n>>> KẾT LUẬN TỪ PYTHON: Bức ảnh này là CLASS {pred_class} ({class_map[pred_class].upper()})")
    print(f">>> HÃY NHÌN LÊN BOARD DE10-LITE: LED 7 ĐOẠN CÓ HIỆN 'CLASS {pred_class}' KHÔNG?")
    print(">>> Nếu khớp nhau -> RTL thiết kế chuẩn. Model Train kém hoặc nét vẽ chưa giống dataset!")
    print(">>> Nếu lệch nhau -> Lỗi phần cứng RTL (Tràn số, rác thanh ghi...)!")