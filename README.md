
# 🚀 WP Docker LEMP Stack

[![Phiên bản](https://img.shields.io/badge/version-v1.0.3--beta-blue)](https://github.com/thachpn165/wp-lemp-docker/releases)
[![Docker Support](https://img.shields.io/badge/docker-ready-blue)](https://www.docker.com/)
[![macOS & Linux](https://img.shields.io/badge/os-macOS%20%7C%20Linux-green)](https://github.com/thachpn165/wp-lemp-docker/)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker-lemp)](./LICENSE)
[![Made with ❤️](https://img.shields.io/badge/made%20with-%E2%9D%A4-red)](https://github.com/thachpn165/wp-lemp-docker/)

---

![menu](https://raw.githubusercontent.com/thachpn165/wp-docker-lemp/refs/heads/main/menu-screenshot.png)

## 📝 Giới thiệu

**WP Docker LEMP Stack** là hệ thống quản lý WordPress nhiều website thông qua Docker với giao diện menu trực quan trong terminal.  
Tự động cấu hình NGINX, SSL, backup định kỳ, upload cloud (Rclone), WP-CLI và nhiều tiện ích mở rộng.

Dự án hướng tới: **đơn giản – dễ dùng – dễ mở rộng**, chạy mượt trên **macOS & Linux**.

---

## 🌟 Mục tiêu dự án

- ✅ Quản lý nhiều website WordPress trên cùng 1 server
- ✅ Tích hợp SSL (tự ký, Let's Encrypt, thủ công)
- ✅ Tự động backup và upload lên cloud (GDrive, OneDrive…)
- ✅ Giao diện terminal trực quan, dễ thao tác
- ✅ Quản lý WP-CLI, log, cronjob dễ dàng
- ✅ Dễ bảo trì nhờ cấu trúc module hoá rõ ràng

---

## 🆕 Có gì mới trong `v1.0.3-beta`?

### 🐘 Quản lý phiên bản PHP:
- Cho phép chọn PHP cho từng website (ví dụ: 7.4, 8.1, 8.4…)
- Tự động dừng & chạy lại container PHP khi đổi version
- Giao diện chọn PHP từ danh sách trực quan
- Cảnh báo nếu chọn PHP 7.4 trên môi trường ARM (Apple Silicon…)

### 🛠️ Sửa cấu hình PHP trực tiếp:
- Cho phép chọn trình soạn thảo (nano, vi, vim, micro, code…)
- Hiển thị hướng dẫn sử dụng từng editor trước khi sửa
- Tự động restart container PHP sau khi sửa `php.ini` hoặc `php-fpm.conf`

### 🔧 Cập nhật:
- `setup-system.sh` kiểm tra và tự cài đặt `nano`, `vim` nếu thiếu
- Danh sách PHP được lấy trực tiếp từ Docker Hub (Bitnami)
- Hạn chế lỗi `"manifest not found"` bằng cách sử dụng đúng tag thật

---

## 🧱 Cấu trúc hệ thống

```bash
.
├── install.sh               # Cài đặt hệ thống
├── update.sh                # Cập nhật từ GitHub
├── uninstall.sh             # Gỡ toàn bộ hệ thống
├── shared/
│   ├── bin/wp               # WP-CLI binary
│   ├── config/config.sh     # Biến cấu hình toàn cục
│   └── scripts/functions/   # Các module chức năng
├── sites/                   # Chứa các site WordPress
│   └── [site_name]/
│       ├── wordpress/       # Mã nguồn WP
│       ├── logs/            # Log hệ thống & backup
│       ├── backups/         # File backup
│       ├── php/             # PHP config
│       └── mariadb/         # DB config
└── nginx-proxy/             # NGINX Proxy chung
    ├── conf.d/              # Config từng site
    ├── ssl/                 # Chứng chỉ SSL
    └── globals/             # Global config, cache, WAF
```

---

## ⚙️ Yêu cầu hệ thống

- Docker: >= 20.10
- Docker Compose plugin: >= 2.0
- macOS hoặc Linux (Ubuntu/Debian/CentOS)
- Không yêu cầu giao diện đồ hoạ

---

## 🚀 Cài đặt nhanh

```bash
curl -Lso- https://raw.githubusercontent.com/thachpn165/wp-docker-lemp/main/install.sh | bash
```

> Hoặc:

```bash
git clone https://github.com/thachpn165/wp-docker-lemp
cd wp-docker-lemp
chmod +x install.sh && ./install.sh
```

---

## 💡 Cách sử dụng

```bash
cd wp-docker-lemp
bash main.sh
```

---

## 🔧 Tính năng nổi bật

- 🌍 Tạo và quản lý nhiều website WordPress
- 🔀 Thay đổi phiên bản PHP cho từng site
- 🔐 Tự động cài SSL (Let's Encrypt, thủ công, tự ký)
- 🔁 Backup + upload lên cloud (qua Rclone)
- 🗓 Lên lịch backup định kỳ (cron)
- ⚙️ Sửa trực tiếp `php.ini`, `php-fpm.conf`
- 🔍 Kiểm tra SSL, thông tin site, logs
- 💥 Xoá site hoàn toàn (container, file, SSL, cronjob)

---

## ☁️ Tích hợp Rclone

- Hỗ trợ: Google Drive, OneDrive, Dropbox, Mega.nz...
- Cài đặt đơn giản bằng script:

```bash
./shared/scripts/functions/rclone/setup_rclone.sh
```

---

## 📦 Cập nhật phiên bản

```bash
./update.sh
```

> `main.sh` sẽ tự kiểm tra nếu có phiên bản mới và hiển thị gợi ý cập nhật.

---

## 📋 Changelog (v1.0.3-beta)

```text
- Thêm menu Quản lý PHP riêng
- Hỗ trợ chọn phiên bản PHP khi tạo website mới
- Cho phép sửa php.ini và php-fpm.conf với editor tùy chọn
- Tự động restart container PHP khi thay đổi cấu hình
- Cải thiện lấy danh sách PHP từ Docker Hub (Bitnami)
- Fix lỗi không hiển thị danh sách PHP do dùng subshell
```

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

---
