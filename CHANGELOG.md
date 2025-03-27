# 📦 CHANGELOG – WP Docker LEMP

## [v1.0.8-beta] - 2025-03-30

### Added
- **Refactor**: Tối ưu hóa và thay thế các lệnh `cd` trong script bằng hàm `run_in_dir` để tránh thay đổi thư mục làm việc, giúp tăng tính linh hoạt và bảo mật trong quá trình thực thi.
- **Support for TEST_MODE**: Đảm bảo TEST_MODE được kiểm soát chặt chẽ trong môi trường test và trong mã thực tế. Thêm biến môi trường `TEST_MODE` và `TEST_ALWAYS_READY` vào cấu hình để đảm bảo mã chạy đúng trong môi trường kiểm tra tự động.
- **Container and Volume Checks**: Thêm các hàm `is_container_running` và `is_volume_exist` được tối ưu hóa với thông báo debug rõ ràng, hỗ trợ việc kiểm tra trạng thái container và volumes khi thực hiện các thao tác Docker.
- **Test Enhancements**: Cải thiện các bài kiểm tra tự động trong `bats` bằng cách mock các chức năng cần thiết, tránh gặp phải các lỗi liên quan đến môi trường khi chạy các thử nghiệm trên Github Actions và môi trường thực tế.
  
### Fixed
- **Docker Compose Container Startup**: Sửa lỗi trong quá trình kiểm tra và khởi động container `nginx-proxy` để đảm bảo quá trình chờ khởi động và kiểm tra trạng thái container được thực hiện chính xác trong các môi trường khác nhau.
- **File System Permissions**: Đảm bảo các tệp cấu hình Docker và các tệp cần thiết không bị lỗi quyền truy cập khi thực thi trên các môi trường khác nhau (Linux/macOS).

### Changed
- **Update Script Refactoring**: Cải tiến mã nguồn của các script liên quan đến cập nhật và phục hồi (update) hệ thống để loại trừ các thư mục không cần thiết (sites, logs) và không làm mất dữ liệu quan trọng khi chạy các lệnh cập nhật tự động.
- **Log Output Adjustments**: Tinh chỉnh thông báo lỗi và thông tin quá trình trong log để dễ dàng theo dõi và phân tích trong quá trình chạy các script cài đặt và cập nhật hệ thống.

## [v1.0.7-beta] - 2025-03-23

### Added
- **Support for managing SSL certificates**: Thêm các tính năng quản lý chứng chỉ SSL bao gồm:
  - Cài đặt chứng chỉ tự ký (self-signed).
  - Cài đặt chứng chỉ từ Let's Encrypt (miễn phí).
  - Kiểm tra trạng thái chứng chỉ SSL, bao gồm ngày hết hạn và tình trạng hợp lệ.
  - Quản lý các chứng chỉ SSL trong NGINX Proxy.
- **Backup improvements**: Cải thiện tính năng sao lưu, đảm bảo việc sao lưu và phục hồi không gặp phải lỗi với các tệp cấu hình và thư mục dữ liệu quan trọng.

### Fixed
- **Docker Compose compatibility**: Đảm bảo tính tương thích với các phiên bản Docker Compose mới, bao gồm việc xử lý các container và volumes Docker một cách chính xác hơn.
- **Script execution in different environments**: Đảm bảo các script cài đặt và quản lý hoạt động ổn định trên cả macOS và Linux, đặc biệt là khi thực hiện các thao tác với Docker và NGINX.

### Changed
- **Refactor system configuration**: Cải tiến cấu trúc mã nguồn của các script cài đặt và quản lý để dễ dàng mở rộng và bảo trì. Sử dụng hàm chung và đơn giản hóa các bước cài đặt chứng chỉ SSL.
- **Improved Docker container startup checks**: Cải tiến việc kiểm tra và khởi động các container Docker, đặc biệt là trong trường hợp container `nginx-proxy` không khởi động đúng.

### Removed
- **Deprecated SSL certificate management code**: Loại bỏ mã cũ không còn sử dụng để quản lý chứng chỉ SSL, thay vào đó sử dụng các hàm mới và dễ bảo trì hơn.

### Misc
- **Bugfixes and optimization**: Tối ưu hóa mã nguồn, sửa các lỗi nhỏ và cải tiến các thông báo lỗi trong các bước cài đặt và kiểm tra.


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
