# Lấy ID của board đang cắm
set hw_name [lindex [get_hardware_names] 0]
set dev_name [lindex [get_device_names -hardware_name $hw_name] 0]

# 1. Ghi ảnh vào RAM (Instance 0 là RAM IMG0)
begin_memory_edit -hardware_name $hw_name -device_name $dev_name
# ĐÃ SỬA LỖI: Thêm tham số -mem_file_type mif
update_content_to_memory_from_file -instance_index 0 -mem_file_path "live_image.mif" -mem_file_type mif
end_memory_edit

# 2. Đẩy nút bấm ISSP lên 1 rồi hạ xuống 0 (Tạo xung Start)
start_insystem_source_probe -hardware_name $hw_name -device_name $dev_name
write_source_data -instance_index 0 -value 1
write_source_data -instance_index 0 -value 0
end_insystem_source_probe


