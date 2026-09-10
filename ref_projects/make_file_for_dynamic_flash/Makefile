# ==============================================================================
# DE10-NANO FPGA DYNAMIC DEVICE TREE OVERLAY MANAGER
# Robust version
#
# Dùng để nạp động device tree khi linux đang boot nhe các bạn, ví dụ các target
#   make build simple_adder
#   make clean simple_adder
#   make clean_all simple_adder
#   make clear simple_adder
# ==============================================================================


# ------------------------------------------------------------------------------
# PROJECT SELECTION
# ------------------------------------------------------------------------------

# Lấy argument thứ 2:
#   make build simple_adder
#              ^^^^^^^^^^^^
ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
PROJECT_ARG := $(firstword $(ARGS))

# Nếu không truyền project -> mặc định soc_system
PROJECT := $(if $(PROJECT_ARG),$(PROJECT_ARG),soc_system)


# ------------------------------------------------------------------------------
# FILE NAMES
# ------------------------------------------------------------------------------

DTSO := $(PROJECT).dtso
DTBO := $(PROJECT).dtbo
RBF  := $(PROJECT).rbf


# ------------------------------------------------------------------------------
# PATHS
# ------------------------------------------------------------------------------

FW_DIR        := /lib/firmware
CONFIGFS_ROOT := /config
CONFIGFS_DIR  := $(CONFIGFS_ROOT)/device-tree/overlays
OVERLAY_PATH  := $(CONFIGFS_DIR)/$(PROJECT)

FPGA_MGR_STATE := /sys/class/fpga_manager/fpga0/state


# ------------------------------------------------------------------------------
# COLORS
# ------------------------------------------------------------------------------

CYAN  := \033[1;36m
GREEN := \033[1;32m
RED   := \033[1;31m
YELLOW := \033[1;33m
NC    := \033[0m


# ------------------------------------------------------------------------------
# MAKE SETTINGS
# ------------------------------------------------------------------------------

.DEFAULT_GOAL := help

# Nếu recipe fail, make không giữ lại target đang tạo dở.
.DELETE_ON_ERROR:

# Không cho chạy song song vì đang thao tác FPGA/configfs.
.NOTPARALLEL:

.SECONDARY: $(RBF)

.PHONY: \
	help all build clean clean_all clear \
	check_rbf check_conflicts ensure_configfs FORCE


# ------------------------------------------------------------------------------
# Dummy target cho:
#
#   make build simple_adder
#
# Nếu không có đoạn này make sẽ hiểu simple_adder là một target riêng.
# ------------------------------------------------------------------------------

ifneq ($(strip $(PROJECT_ARG)),)
.PHONY: $(PROJECT_ARG)

$(PROJECT_ARG):
	@:
endif


# ------------------------------------------------------------------------------
# FORCE
# ------------------------------------------------------------------------------

FORCE:


# ==============================================================================
# HELP
# ==============================================================================

help:
	@printf "$(CYAN)======================================================================$(NC)\n"
	@printf "$(GREEN)  DE10-NANO FPGA DYNAMIC DEVICE TREE OVERLAY MANAGER$(NC)\n"
	@printf "$(CYAN)======================================================================$(NC)\n"
	@printf "\n"
	@printf "Usage:\n"
	@printf "  $(YELLOW)make <command> [project]$(NC)\n"
	@printf "\n"
	@printf "Commands:\n"
	@printf "  $(GREEN)help$(NC)      Show this help.\n"
	@printf "\n"
	@printf "  $(GREEN)build$(NC)     Validate files, compile DTBO and configure FPGA.\n"
	@printf "             Example: $(YELLOW)make build simple_adder$(NC)\n"
	@printf "\n"
	@printf "  $(GREEN)clean$(NC)     Remove current project's active overlay.\n"
	@printf "             Example: $(YELLOW)make clean simple_adder$(NC)\n"
	@printf "\n"
	@printf "  $(GREEN)clean_all$(NC) Remove ALL active overlays and current project's\n"
	@printf "             firmware files.\n"
	@printf "             Example: $(YELLOW)make clean_all simple_adder$(NC)\n"
	@printf "\n"
	@printf "  $(GREEN)clear$(NC)     Remove generated DTBO/temp files.\n"
	@printf "             Custom DTSO is preserved.\n"
	@printf "             Example: $(YELLOW)make clear simple_adder$(NC)\n"
	@printf "\n"
	@printf "Default project: $(YELLOW)soc_system$(NC)\n"
	@printf "$(CYAN)======================================================================$(NC)\n"


# ==============================================================================
# ALL
# ==============================================================================

all: build


# ==============================================================================
# CONFIGFS
# ==============================================================================

ensure_configfs:
	@mkdir -p "$(CONFIGFS_ROOT)"
	@if ! mountpoint -q "$(CONFIGFS_ROOT)"; then \
		printf "$(CYAN)Mounting ConfigFS...$(NC)\n"; \
		if ! mount -t configfs configfs "$(CONFIGFS_ROOT)"; then \
			printf "$(RED)ERROR: Cannot mount ConfigFS.$(NC)\n"; \
			exit 1; \
		fi; \
	fi
	@if [ ! -d "$(CONFIGFS_DIR)" ]; then \
		printf "$(RED)ERROR: Device Tree overlay ConfigFS interface not found:$(NC)\n"; \
		printf "  $(CONFIGFS_DIR)\n"; \
		printf "Check CONFIG_OF_CONFIGFS / CONFIG_OF_OVERLAY.\n"; \
		exit 1; \
	fi


# ==============================================================================
# DTSO
# ==============================================================================
#
# Quan trọng:
#
# Không chỉ test "-f".
#
# -f:
#   file 0 byte vẫn được xem là tồn tại.
#
# -s:
#   file phải tồn tại VÀ size > 0.
#
# FORCE buộc recipe này chạy mỗi lần build để bắt trường hợp DTSO bị truncate.
#
# Nếu DTSO tồn tại và có dữ liệu -> KHÔNG sửa, bảo vệ custom DTSO.
# Nếu không tồn tại hoặc 0 byte -> tạo template mới.
# ==============================================================================

$(DTSO): FORCE
	@if [ ! -s "$@" ]; then \
		if [ -e "$@" ]; then \
			printf "$(RED)WARNING: $@ exists but is EMPTY.$(NC)\n"; \
			printf "$(YELLOW)Recreating template...$(NC)\n"; \
		else \
			printf "$(CYAN)Creating template $@...$(NC)\n"; \
		fi; \
		TMP="$@.tmp"; \
		rm -f "$$TMP"; \
		{ \
			echo "/dts-v1/;"; \
			echo "/plugin/;"; \
			echo ""; \
			echo "/* AUTO-GENERATED BY DE10-NANO MAKEFILE */"; \
			echo ""; \
			echo "/ {"; \
			echo "    fragment@0 {"; \
			echo "        target-path = \"/soc/base_fpga_region\";"; \
			echo ""; \
			echo "        __overlay__ {"; \
			echo "            #address-cells = <1>;"; \
			echo "            #size-cells = <1>;"; \
			echo "            firmware-name = \"$(RBF)\";"; \
			echo "        };"; \
			echo "    };"; \
			echo "};"; \
		} > "$$TMP"; \
		if [ ! -s "$$TMP" ]; then \
			printf "$(RED)ERROR: Failed to generate $@.$(NC)\n"; \
			rm -f "$$TMP"; \
			exit 1; \
		fi; \
		mv -f "$$TMP" "$@"; \
	else \
		printf "$(YELLOW)Using existing DTSO: $@$(NC)\n"; \
	fi


# ==============================================================================
# DTBO
# ==============================================================================
#
# Compile vào .tmp trước.
#
# Chỉ khi:
#   1. dtc compile OK
#   2. output != 0 byte
#   3. dtc đọc ngược lại được DTBO
#
# thì mới mv thành DTBO thật.
#
# Nhờ vậy không còn trường hợp DTBO 0 byte nằm lại sau compile lỗi.
# ==============================================================================

$(DTBO): $(DTSO) FORCE
	@printf "$(CYAN)Compiling Device Tree Overlay...$(NC)\n"
	@TMP="$@.tmp"; \
	rm -f "$$TMP"; \
	if ! dtc -@ -I dts -O dtb -o "$$TMP" "$(DTSO)"; then \
		printf "$(RED)ERROR: DTC compilation failed.$(NC)\n"; \
		rm -f "$$TMP"; \
		exit 1; \
	fi; \
	if [ ! -s "$$TMP" ]; then \
		printf "$(RED)ERROR: DTC produced an EMPTY DTBO.$(NC)\n"; \
		rm -f "$$TMP"; \
		exit 1; \
	fi; \
	if ! dtc -I dtb -O dts "$$TMP" >/dev/null 2>&1; then \
		printf "$(RED)ERROR: Generated DTBO is invalid/corrupted.$(NC)\n"; \
		rm -f "$$TMP"; \
		exit 1; \
	fi; \
	mv -f "$$TMP" "$@"; \
	printf "$(GREEN)DTBO valid: $@$(NC)\n"


# ==============================================================================
# RBF VALIDATION
# ==============================================================================

check_rbf:
	@if [ ! -e "$(RBF)" ]; then \
		printf "$(RED)ERROR: $(RBF) does not exist.$(NC)\n"; \
		exit 1; \
	fi
	@if [ ! -f "$(RBF)" ]; then \
		printf "$(RED)ERROR: $(RBF) is not a regular file.$(NC)\n"; \
		exit 1; \
	fi
	@if [ ! -s "$(RBF)" ]; then \
		printf "$(RED)ERROR: $(RBF) is EMPTY (0 bytes)!$(NC)\n"; \
		printf "$(RED)FPGA programming aborted.$(NC)\n"; \
		exit 1; \
	fi
	@if [ ! -r "$(RBF)" ]; then \
		printf "$(RED)ERROR: $(RBF) is not readable.$(NC)\n"; \
		exit 1; \
	fi
	@printf "$(GREEN)RBF OK: $(RBF) ($$(stat -c%s "$(RBF)") bytes)$(NC)\n"


# ==============================================================================
# OVERLAY CONFLICT CHECK
# ==============================================================================

check_conflicts: ensure_configfs
	@OTHER=""; \
	for D in "$(CONFIGFS_DIR)"/*; do \
		[ -d "$$D" ] || continue; \
		[ "$$D" = "$(OVERLAY_PATH)" ] && continue; \
		OTHER="$$OTHER $$(basename "$$D")"; \
	done; \
	if [ -n "$$OTHER" ]; then \
		printf "$(YELLOW)WARNING: Other overlays are currently active:$(NC)\n"; \
		for O in $$OTHER; do \
			printf "  - %s\n" "$$O"; \
		done; \
		printf "$(YELLOW)FPGA region may be busy. Use clean/clean_all if required.$(NC)\n"; \
	fi


# ==============================================================================
# BUILD
# ==============================================================================

build: check_rbf $(DTBO) check_conflicts
	@printf "$(CYAN)======================================================================$(NC)\n"
	@printf "$(CYAN)Processing FPGA project: $(PROJECT)$(NC)\n"
	@printf "$(CYAN)======================================================================$(NC)\n"

	@mkdir -p "$(FW_DIR)"

	@printf "$(CYAN)Copying firmware safely...$(NC)\n"
	@set -e; \
	RBF_TMP="$(FW_DIR)/.$(RBF).tmp"; \
	DTBO_TMP="$(FW_DIR)/.$(DTBO).tmp"; \
	rm -f "$$RBF_TMP" "$$DTBO_TMP"; \
	cp "$(RBF)" "$$RBF_TMP"; \
	cp "$(DTBO)" "$$DTBO_TMP"; \
	if [ ! -s "$$RBF_TMP" ]; then \
		printf "$(RED)ERROR: Firmware RBF copy became EMPTY.$(NC)\n"; \
		rm -f "$$RBF_TMP" "$$DTBO_TMP"; \
		exit 1; \
	fi; \
	if [ ! -s "$$DTBO_TMP" ]; then \
		printf "$(RED)ERROR: Firmware DTBO copy became EMPTY.$(NC)\n"; \
		rm -f "$$RBF_TMP" "$$DTBO_TMP"; \
		exit 1; \
	fi; \
	if ! cmp -s "$(RBF)" "$$RBF_TMP"; then \
		printf "$(RED)ERROR: RBF copy verification failed.$(NC)\n"; \
		rm -f "$$RBF_TMP" "$$DTBO_TMP"; \
		exit 1; \
	fi; \
	if ! cmp -s "$(DTBO)" "$$DTBO_TMP"; then \
		printf "$(RED)ERROR: DTBO copy verification failed.$(NC)\n"; \
		rm -f "$$RBF_TMP" "$$DTBO_TMP"; \
		exit 1; \
	fi; \
	mv -f "$$RBF_TMP" "$(FW_DIR)/$(RBF)"; \
	mv -f "$$DTBO_TMP" "$(FW_DIR)/$(DTBO)"

	@printf "$(GREEN)Firmware copy verified.$(NC)\n"

	@if [ -d "$(OVERLAY_PATH)" ]; then \
		printf "$(YELLOW)Overlay $(PROJECT) already active. Reloading...$(NC)\n"; \
		if ! rmdir "$(OVERLAY_PATH)"; then \
			printf "$(RED)ERROR: Cannot remove existing overlay.$(NC)\n"; \
			printf "$(YELLOW)Recent kernel messages:$(NC)\n"; \
			dmesg | tail -30; \
			exit 1; \
		fi; \
		sleep 1; \
	fi

	@mkdir "$(OVERLAY_PATH)"

	@printf "$(CYAN)Applying overlay $(DTBO)...$(NC)\n"

	@if echo "$(DTBO)" > "$(OVERLAY_PATH)/path"; then \
		printf "$(GREEN)Device Tree overlay applied.$(NC)\n"; \
	else \
		printf "$(RED)ERROR: Failed to apply $(DTBO).$(NC)\n"; \
		printf "$(YELLOW)Recent kernel messages:$(NC)\n"; \
		dmesg | tail -40; \
		rmdir "$(OVERLAY_PATH)" 2>/dev/null || true; \
		exit 1; \
	fi

	@if [ -r "$(FPGA_MGR_STATE)" ]; then \
		FPGA_STATE=$$(cat "$(FPGA_MGR_STATE)"); \
		printf "$(CYAN)FPGA Manager state: $$FPGA_STATE$(NC)\n"; \
		if [ "$$FPGA_STATE" != "operating" ]; then \
			printf "$(RED)ERROR: FPGA Manager is not in operating state.$(NC)\n"; \
			dmesg | tail -40; \
			exit 1; \
		fi; \
	fi

	@printf "$(CYAN)Checking FPGA-to-SDRAM bridge...$(NC)\n"

	@SDR_STATE=$$(busybox devmem 0xFFC2505C 32); \
	printf "SDRAM bridge register: $$SDR_STATE\n"; \
	case "$$SDR_STATE" in \
		*[Aa]*) \
			printf "$(YELLOW)SDRAM ports already configured. Skipping configuration.$(NC)\n"; \
			;; \
		*) \
			printf "$(CYAN)Configuring FPGA-to-SDRAM bridge...$(NC)\n"; \
			if ! busybox devmem 0xFFC25080 32 0x0; then exit 1; fi; \
			if ! busybox devmem 0xFFC2505C 32 0xA; then exit 1; fi; \
			if ! busybox devmem 0xFFC25080 32 0xFFFF; then exit 1; fi; \
			;; \
	esac

	@printf "$(GREEN)======================================================================$(NC)\n"
	@printf "$(GREEN)SUCCESS: FPGA configured with $(PROJECT).$(NC)\n"
	@printf "$(GREEN)======================================================================$(NC)\n"


# ==============================================================================
# CLEAN
# ==============================================================================

clean:
	@printf "$(CYAN)--- Unloading $(PROJECT) ---$(NC)\n"

	@if ! mountpoint -q "$(CONFIGFS_ROOT)"; then \
		printf "$(YELLOW)ConfigFS is not mounted. No overlay to remove.$(NC)\n"; \
	elif [ -d "$(OVERLAY_PATH)" ]; then \
		if rmdir "$(OVERLAY_PATH)"; then \
			printf "$(GREEN)Overlay $(PROJECT) removed.$(NC)\n"; \
		else \
			printf "$(RED)ERROR: Failed to remove overlay $(PROJECT).$(NC)\n"; \
			dmesg | tail -30; \
			exit 1; \
		fi; \
	else \
		printf "$(YELLOW)Overlay $(PROJECT) not found in ConfigFS.$(NC)\n"; \
	fi


# ==============================================================================
# CLEAN ALL
# ==============================================================================
#
# Gỡ toàn bộ active overlays.
#
# Chỉ xóa firmware của PROJECT hiện tại.
# Tuyệt đối KHÔNG rm wildcard toàn bộ /lib/firmware.
# ==============================================================================

clean_all:
	@printf "$(RED)--- CLEANING ALL ACTIVE FPGA OVERLAYS ---$(NC)\n"

	@if mountpoint -q "$(CONFIGFS_ROOT)"; then \
		for D in "$(CONFIGFS_DIR)"/*; do \
			[ -d "$$D" ] || continue; \
			printf "Removing overlay: %s\n" "$$(basename "$$D")"; \
			if ! rmdir "$$D"; then \
				printf "$(RED)WARNING: Could not remove $$D$(NC)\n"; \
			fi; \
		done; \
	else \
		printf "$(YELLOW)ConfigFS not mounted. No active overlays.$(NC)\n"; \
	fi

	@printf "Removing firmware for project $(PROJECT)...\n"
	@rm -f "$(FW_DIR)/$(RBF)"
	@rm -f "$(FW_DIR)/$(DTBO)"
	@rm -f "$(FW_DIR)/.$(RBF).tmp"
	@rm -f "$(FW_DIR)/.$(DTBO).tmp"

	@printf "$(GREEN)Clean-all complete.$(NC)\n"


# ==============================================================================
# CLEAR LOCAL GENERATED FILES
# ==============================================================================
#
# Không xóa DTSO vì DTSO có thể chứa custom fragments do user viết.
# DTBO luôn có thể regenerate từ DTSO.
# ==============================================================================

clear:
	@printf "$(CYAN)Cleaning generated files for $(PROJECT)...$(NC)\n"

	@rm -f "$(DTBO)"
	@rm -f "$(DTBO).tmp"
	@rm -f "$(DTSO).tmp"

	@printf "$(YELLOW)Preserved source DTSO: $(DTSO)$(NC)\n"
	@printf "$(GREEN)Done.$(NC)\n"
