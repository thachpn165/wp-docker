# 📦 CHANGELOG – WP Docker LEMP

## [v1.0.6-beta] - 2025-03-26

### 🚀 Tính năng mới

- **Hỗ trợ chạy bằng lệnh `wpdocker`** từ bất kỳ thư mục nào
- **Thêm script `install.sh` mới**:
  - Tự động tải bản release mới nhất từ GitHub
  - Giải nén vào `/opt/wp-docker`
  - Tạo symlink `/usr/local/bin/wpdocker`
  - Kiểm tra hệ điều hành và cảnh báo (macOS cần thêm `/opt` vào Docker File Sharing)
- **Thêm script `uninstall.sh`**:
  - Cho phép sao lưu toàn bộ site trước khi gỡ
  - Xóa sạch container, volume, cấu hình, cronjob và mã nguồn

### 🔧 Cải tiến

- Tối ưu lại `setup-system.sh`:
  - Kiểm tra Docker & Docker Compose
  - Chờ `nginx-proxy` khởi động xong rồi mới tiếp tục
  - Hiển thị log nếu `nginx-proxy` khởi động thất bại
- Cải tiến script `wpdocker.sh` để chạy đúng `main.sh` từ đường dẫn cài đặt mới
- Hỗ trợ **symlink thư mục `/opt/wp-docker` đến mã nguồn local** để dev/test dễ dàng

### 🛠 Fix lỗi

- Fix lỗi `wp: Permission denied` khi chạy WP-CLI trong container
- Fix lỗi mount trên macOS do thiếu quyền chia sẻ thư mục `/opt`
- Fix lỗi cấu hình `docker-compose.override.yml` không đồng bộ mount path
- Fix lỗi kiểm tra quyền ghi file `php_versions.txt`

### 💡 Ghi chú

- Trên **macOS**, bắt buộc phải thêm `/opt` vào Docker → Settings → File Sharing để tránh lỗi mount
- Nếu bạn đang dev và muốn test bằng source local:
  ```bash
  sudo rm -rf /opt/wp-docker
  sudo ln -s ~/wp-docker-lemp/src /opt/wp-docker
