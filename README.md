# 🚧 Đang phát triển
🔹 Phiên bản `v1.0.6-beta` đang trong giai đoạn hoàn thiện và có thể thay đổi trước khi ra mắt bản stable.

# 🚀 WP Docker

[![Phiên bản](https://img.shields.io/badge/version-v1.0.6--beta-blue)](https://github.com/thachpn165/wp-docker/releases)
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

## V1.0.6-beta có gì mới?

### 🚀 Cài đặt nhanh và gọn

- Hỗ trợ lệnh `wpdocker` để truy cập menu
- Tích hợp check `brew`, `apt`, `yum` cho macOS & Linux

### 🛠 Uninstall toàn diện

- Hỏi backup trước khi xóa
- Backup DB + WP source vào `archives/`
- Xóa container, volume, SSL, config, cronjob, docker-compose.override.yml
- Reload nginx-proxy sau khi xóa site

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
