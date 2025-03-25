## [v1.0.3-beta] - 2024-03-25
### Added
- Tính năng quản lý phiên bản PHP cho từng website
- Tích hợp vào `main.sh` menu Quản lý PHP
- Giao diện chọn trình soạn thảo khi sửa `php.ini`, `php-fpm.conf`
- `setup-system.sh` kiểm tra và cài `nano`, `vim`, ...

### Improved
- `create-website.sh` tích hợp chọn PHP từ danh sách thay vì nhập tay
- Chuyển đổi logic `php84` → `8.4` để tương thích Docker Hub

### Fixed
- Lỗi không hiển thị danh sách PHP do dùng subshell
