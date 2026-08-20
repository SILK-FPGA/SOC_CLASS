# CÁCH NẠP FILE CẤU HÌNH VÀ CHẠY TRÊN WEB REMOTE LAB
# Nạp file rbf 
Lên web remote lab, chọn board de10 nano 2, phần giao diện để tương tác như hình dưới:

<img width="1167" height="787" alt="image" src="https://github.com/user-attachments/assets/8be6a596-2507-4920-9302-e27268a1783b" />

Chọn nạp file rbf thông qua nút "Upload and Program" để upload file bnn_49.rbf, trong thư mục output_files/final_rbf/ tại github này:

<img width="1114" height="839" alt="image" src="https://github.com/user-attachments/assets/c0b751ba-0c0b-4ea9-bc72-c2cb17b33888" />

Sau khi nạp xong, upload ảnh cần test lên với nút "UPLOAD FILE LÊN BOARD", ở đây ta up ảnh trong thư mục software/fpga_test_vectors tại github này, ví dụ với ảnh test_img_0.txt.

<img width="1011" height="839" alt="image" src="https://github.com/user-attachments/assets/18ab4f9b-e0d4-4dc1-8fca-f1183ce18461" />

# Chạy code C
Mở terminal linux trên board:

<img width="1114" height="839" alt="image" src="https://github.com/user-attachments/assets/df36886b-591b-445d-a9fe-aa77cccf3926" />

Di chuyển tới thư mục upload với lệnh "cd upload", đây là thư mục mà ảnh và media do người dùng tải lên sẽ nằm ở đây, và bị xóa đi khi hết phiên, lệnh "ls" để liệt kê các file trong upload, ta thấy file test_img_0.txt được tải lên thành công: 

<img width="1011" height="839" alt="image" src="https://github.com/user-attachments/assets/7e4fd32c-2414-4062-8f0c-052c72e95328" />

Tiếp đến, chạy lệnh "cd" để về root, rồi chạy "run c" để biên dịch code C, cửa sổ mở lên code mẫu, ta xóa đi với "ctrl + K" và copy code C mà ta muốn chạy với lệnh "ctrl + shift + V". Ở đây mình sẽ ví dụ với code mẫu /software/userspace/bnn_customdma.c:

<img width="1011" height="839" alt="image" src="https://github.com/user-attachments/assets/101f96af-c50c-45e6-85b3-00875bc6e008" />

Sau khi copy code mẫu

<img width="1390" height="951" alt="image" src="https://github.com/user-attachments/assets/a58cd55f-92b7-44f6-8e65-d0a30144a993" />

Chạy lệnh "ctrl + X" --> ấn phím y trên bàn phím laptop --> Enter --> Board tự động biên dịch. Hiện ra màn hình nhập tham số như hình dưới.

<img width="1390" height="951" alt="image" src="https://github.com/user-attachments/assets/e3a12a9c-2cad-4a8d-8975-81706661b276" />

Ta nhập ảnh cần test: "upload/test_img_0.txt"

<img width="1390" height="951" alt="image" src="https://github.com/user-attachments/assets/7c825322-9e1f-404c-8b80-acb7cdc83cde" />

Sau đó nhấn enter để chờ kết quả trả về từ fpga:

<img width="1390" height="951" alt="image" src="https://github.com/user-attachments/assets/a238ced6-5c49-481b-901a-bed037b31a7a" />
