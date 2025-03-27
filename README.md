# 🚧 Đang phát triển
🔹 Phiên bản `v1.0.7-beta` đang trong giai đoạn hoàn thiện và có thể thay đổi trước khi ra mắt bản stable.

# 🚀 WP Docker

[![Phiên bản](https://img.shields.io/badge/version-v1.0.7--beta-blue)](https://github.com/thachpn165/wp-docker/releases)
[![Docker Support](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)](https://github.com/thachpn165/wp-docker)
[![Linux](https://img.shields.io/badge/Linux-supported-success?logo=linux)](https://github.com/thachpn165/wp-docker)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker)](./LICENSE)

---

![menu](https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/menu-screenshot.png)

## 📝 Giới thiệu

**WP Docker LEMP Stack** là hệ thống quản lý nhiều website WordPress qua Docker với giao diện menu tương tác trong terminal. 
Tự động cài WP, sinh SSL, backup, WP-CLI, upload cloud...

Hướng đến: **đơn giản – dễ dùng – dễ mở rộng**, hoạt động trên **macOS & Linux**.

---

## 🌟 Mục tiêu dự án

- ✅ Quản lý nhiều website WordPress
- ✅ Tích hợp SSL: Let's Encrypt, tự ký, thủ công
- ✅ Backup định kỳ + upload cloud (GDrive,...)
- ✅ WP-CLI, log, cronjob terminal giao diện
- ✅ Cấu trúc module dễ bảo trì & phát triển

---

## V1.0.7-beta có gì mới?

### 🚀 Cài đặt WP-CLI tự động và cập nhật hệ thống

- **Kiểm tra và cài đặt WP-CLI** tự động nếu chưa có.
- **Cập nhật hệ thống WP Docker** từ GitHub Release mà không làm mất dữ liệu quan trọng.
- **Cập nhật template version** cho các website đã cài đặt, giúp các site sử dụng phiên bản template mới nhất.

### 🛠 Cập nhật hệ thống tự động

- **Tải và giải nén bản release mới nhất** từ GitHub.
- **Loại trừ các thư mục quan trọng** như `sites/`, `logs/`, và `archives/` khi cập nhật.
- **Cập nhật file hệ thống**, nhưng giữ nguyên dữ liệu của người dùng.
- **Kiểm tra và cập nhật template version** cho các website sử dụng phiên bản cũ.

### 🔧 Tính năng bổ sung

- **Tính năng upgrade**: Kiểm tra và chạy **script nâng cấp** nếu có file `upgrade/{version}` trùng với phiên bản mới, giúp cập nhật file template cho các website đang dùng template cũ.
- **Tự động tải và cài đặt WP-CLI** nếu thiếu trong thư mục `shared/bin/`, đồng thời tạo symlink cho lệnh `wp` hoạt động từ bất kỳ thư mục nào.

### 🛑 Cải tiến tính năng uninstall

- **Sao lưu trước khi xóa**: Hỏi người dùng có muốn sao lưu trước khi xóa website không.
- **Sao lưu toàn bộ**: Lưu database và mã nguồn WP vào thư mục `archives/`.
- **Xóa sạch**: Xóa container, volume, SSL, cấu hình NGINX, cronjob và `docker-compose.override.yml` liên quan.
- **Reload nginx-proxy** sau khi xóa website.

---

### 🌎 Cài nhanh `wpdocker`

```bash
curl -L https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/src/install.sh | bash
```

---

## 📓 Changelog (v1.0.6-beta)

```bash
- Tự động tải release + cài vào /opt/wp-docker
- Tạo symlink wp-cli: wpdocker
- Phát hiện macOS và nhắc chia sẻ /opt
- Cải tiến uninstall.sh: backup site, xóa container + volume + SSL
- Fix vấn đề mount logs/wordpress trên Docker macOS
- Kiểm tra container nginx-proxy chạy trước khi tiếp tục
- Hiển thị logs container khi không start được
```

---

## Dành cho Developer

Khi phát triển, hãy lưu ý symlink thư mục `/opt/wp-docker` trên máy đến thư mục của project và luôn test thông qua lệnh `wpdocker` để đảm bảo sự nhất quán.

```bash
sudo rm -rf /opt/wp-docker
sudo ln -s ~/wp-docker-lemp/src /opt/wp-docker
```

> Bây giờ bạn có thể test lệnh `wpdocker` mà code vẫn là source `~/wp-docker-lemp/src/`

### 🚨 Lưu ý cho macOS

Docker trên macOS KHÔNG mount được bất kỳ folder nào ngoài danh sách chia sẻ.

Sau khi cài bạn Cần thêm `/opt` vào Docker → Settings → Resources → File Sharing:

> 🔍 [https://docs.docker.com/desktop/settings/mac/#file-sharing](https://docs.docker.com/desktop/settings/mac/#file-sharing)

---

## Cách sử dụng

```bash
wpdocker
```

Mở menu terminal quản lý WP: tạo site, SSL, backup...


## 🔧 Tính năng nổi bật

- 🌍 Tạo và quản lý nhiều website WordPress
- 🔀 Thay đổi phiên bản PHP cho từng site
- 🔐 Tự động cài SSL (Let's Encrypt, thủ công, tự ký)
- 🔁 Backup + upload lên cloud (qua Rclone)
- 🗓 Lên lịch backup định kỳ (cron)
- ⚙️ Sửa trực tiếp `php.ini`, `php-fpm.conf`
- 🔍 Kiểm tra SSL, thông tin site, logs
- ♻️ Khôi phục site từ backup
- 💥 Xoá site hoàn toàn (container, file, SSL, cronjob)

---

## 🤝 Đóng góp

### Cách tham gia:
1. Fork repo
2. Tạo branch từ `main`
3. Commit & gửi pull request

### Báo lỗi hoặc đề xuất:
- Mở issue tại GitHub repo

---

## 📃 License

Dự án sử dụng [MIT License](./LICENSE)
