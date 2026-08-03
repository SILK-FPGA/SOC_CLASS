# --- CẤU HÌNH ---
# Trick để lấy tham số thứ 2 làm tên project (VD: make build simple_adder)
ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
PROJECT_ARG := $(firstword $(ARGS))
PROJECT := $(if $(PROJECT_ARG),$(PROJECT_ARG),soc_system)

# Tên file
DTSO := $(PROJECT).dtso
DTBO := $(PROJECT).dtbo
RBF  := $(PROJECT).rbf

# Đường dẫn
FW_DIR := /lib/firmware
CONFIGFS_DIR := /config/device-tree/overlays
OVERLAY_PATH := $(CONFIGFS_DIR)/$(PROJECT)

# Mã màu Terminal để text hiển thị trực quan hơn
CYAN  = \033[1;36m
GREEN = \033[1;32m
RED   = \033[1;31m
YELLO = \033[1;33m
NC    = \033[0m # No Color

# Đặt help làm lệnh mặc định khi chỉ gõ "make"
.DEFAULT_GOAL := help

.SECONDARY: $(RBF)
.PHONY: help all build clean clear check_rbf check_conflicts clean_all

# Vô hiệu hóa lỗi "No rule to make target" cho tham số tên project
$(eval $(PROJECT_ARG):;@:)

# B0: Hướng dẫn sử dụng (make help)
help:
	@echo "$(CYAN)======================================================================$(NC)"
	@echo "$(GREEN)  MAKEFILE QUẢN LÝ DYNAMIC DEVICE TREE OVERLAY (FPGA SoC DE10-NANO)$(NC)"
	@echo "$(CYAN)======================================================================$(NC)"
	@echo " Cách sử dụng: $(YELLO)make <lệnh> [tên_project]$(NC)"
	@echo ""
	@echo " Các lệnh khả dụng:"
	@echo "   $(GREEN)help$(NC)      : Hiển thị hướng dẫn này."
	@echo "   $(GREEN)build$(NC)     : Tạo dtso (nếu chưa có), biên dịch dtbo và nạp xuống FPGA."
	@echo "               VD: $(YELLO)make build simple_adder$(NC)"
	@echo "   $(GREEN)clean$(NC)     : Chỉ gỡ IP/Overlay hiện tại khỏi Kernel (giữ nguyên file)."
	@echo "               VD: $(YELLO)make clean simple_adder$(NC)"
	@echo "   $(GREEN)clean_all$(NC) : Gỡ TẤT CẢ Overlay đang chạy và xóa file trong /lib/firmware."
	@echo "               VD: $(YELLO)make clean_all simple_adder$(NC)"
	@echo "   $(GREEN)clear$(NC)     : Xóa file rác sinh ra (.dtso, .dtbo) ở thư mục làm việc."
	@echo "               VD: $(YELLO)make clear simple_adder$(NC)"
	@echo "$(CYAN)======================================================================$(NC)"

# B1: Tạo dtso (Chỉ tạo nếu chưa tồn tại, bảo vệ file đã custom)
$(DTSO):
	@if [ ! -f $@ ]; then \
		echo "$(CYAN)Creating template $@...$(NC)"; \
		echo "/dts-v1/;" > $@; \
		echo "/plugin/;" >> $@; \
		echo "" >> $@; \
		echo "/{" >> $@; \
		echo "    fragment@0 {" >> $@; \
		echo "        target-path = \"/soc/base_fpga_region\";" >> $@; \
		echo "        __overlay__ {" >> $@; \
		echo "            #address-cells = <1>;" >> $@; \
		echo "            #size-cells = <1>;" >> $@; \
		echo "            firmware-name = \"$(RBF)\";" >> $@; \
		echo "        };" >> $@; \
		echo "    };" >> $@; \
		echo "};" >> $@; \
	else \
		echo "$(YELLO)File $@ already exists. Skipping creation to protect custom fragments.$(NC)"; \
	fi

# B2: Compile dtbo
$(DTBO): $(DTSO)
	@echo "$(CYAN)Compiling Device Tree...$(NC)"
	@dtc -O dtb -o $@ -b 0 -@ $< 2>/dev/null || (echo "$(RED)DTC Compilation Failed!$(NC)"; exit 1)

check_rbf:
	@if [ ! -f $(RBF) ]; then \
		echo "$(RED)ERROR: File $(RBF) not found in current directory!$(NC)"; \
		exit 1; \
	fi

# Helper: Kiểm tra xem có overlay nào KHÁC đang chạy không
check_conflicts:
	@if [ -n "$$(ls -A $(CONFIGFS_DIR) 2>/dev/null)" ]; then \
		if [ ! -d "$(OVERLAY_PATH)" ]; then \
			echo "$(YELLO)!!! WARNING !!!$(NC)"; \
			echo "Found other overlays active in $(CONFIGFS_DIR):"; \
			ls -F $(CONFIGFS_DIR); \
			echo "The FPGA region might be busy. If build fails, run 'make clean_all' first."; \
			echo "---------------------------------------------------"; \
		fi \
	fi

# Chuỗi nạp Overlay chính
build: check_rbf check_conflicts $(DTBO)
	@echo "$(CYAN)--- Processing $(PROJECT) ---$(NC)"
	@# QUAN TRỌNG: Dùng -f để ghi đè file cũ, tránh lỗi Error -22
	@cp -f $(RBF) $(FW_DIR)/
	@cp -f $(DTBO) $(FW_DIR)/
	
	@if ! mountpoint -q /config; then \
		mount -t configfs configfs /config; \
	fi
	
	@if [ -d "$(OVERLAY_PATH)" ]; then \
		echo "$(YELLO)WARNING: This specific overlay is already loaded. Re-loading...$(NC)"; \
		rmdir $(OVERLAY_PATH); \
		sleep 0.5; \
	fi
	
	@mkdir -p $(OVERLAY_PATH)
	@echo "Applying overlay..."
	@if echo "$(DTBO)" > $(OVERLAY_PATH)/path; then \
		echo "$(CYAN)Configuring FPGA-to-SDRAM bridge...$(NC)"; \
		busybox devmem 0xFFC25080 32 0x0; \
		busybox devmem 0xFFC2505C 32 0xA; \
		busybox devmem 0xFFC25080 32 0xFFFF; \
		echo "$(GREEN)SUCCESS: FPGA configured with $(PROJECT).$(NC)"; \
	else \
		echo "$(RED)FAILED: IO Error. Likely hardware busy or bitstream invalid.$(NC)"; \
		rmdir $(OVERLAY_PATH); \
		exit 1; \
	fi

# Clean: Chỉ gỡ overlay, giữ file firmware
clean:
	@echo "$(CYAN)--- Unloading $(PROJECT) ---$(NC)"
	@if [ -d "$(OVERLAY_PATH)" ]; then \
		rmdir $(OVERLAY_PATH); \
		echo "$(GREEN)Overlay $(PROJECT) removed.$(NC)"; \
	else \
		echo "$(YELLO)Overlay $(PROJECT) not found in ConfigFS.$(NC)"; \
	fi

# Clean All: Gỡ overlay VÀ XÓA FILE trong /lib/firmware
clean_all:
	@echo "$(RED)--- NUKING ALL OVERLAYS AND FIRMWARE ---$(NC)"
	@# 1. Gỡ bỏ tất cả overlay đang chạy
	@if mountpoint -q /config; then \
		find $(CONFIGFS_DIR) -mindepth 1 -maxdepth 1 -type d -exec rmdir {} + 2>/dev/null || true; \
		echo "All active overlays removed."; \
	else \
		echo "ConfigFS not mounted, nothing to clean."; \
	fi
	
	@# 2. Xóa file trong /lib/firmware (Chỉ xóa file của project hiện tại để an toàn)
	@echo "Removing $(RBF) and $(DTBO) from $(FW_DIR)..."
	@rm -f $(FW_DIR)/$(RBF)
	@rm -f $(FW_DIR)/$(DTBO)
	@echo "$(GREEN)Nuclear clean complete.$(NC)"

clear:
	@echo "$(CYAN)Cleaning generated files in current folder...$(NC)"
	@rm -f $(DTSO) $(DTBO)
	@echo "$(GREEN)Done.$(NC)"

