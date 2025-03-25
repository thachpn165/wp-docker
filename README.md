
# 🚧 Đang phát triển
Đây là phiên bản chưa hoàn thiện và có thể sẽ có nhiều thay đổi khi sử dụng trước khi phiên bản v1.0-stable ra mắt.

# 🚀 WP Docker

[![Phiên bản](https://img.shields.io/badge/version-v1.0.4--beta-blue)](https://github.com/thachpn165/wp-lemp-docker/releases)
[![Docker Support](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)](https://github.com/thachpn165/wp-docker-lemp)
[![Linux](https://img.shields.io/badge/Linux-supported-success?logo=linux)](https://github.com/thachpn165/wp-docker-lemp)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker-lemp)](./LICENSE)
[![Made with ChatGPT](https://img.shields.io/badge/made%20with-ChatGPT-teal)](https://github.com/thachpn165/wp-lemp-docker/)
[![Discussions](https://img.shields.io/badge/💬%20Thảo%20luận%20trên%20GitHub-blue?logo=github)](https://github.com/thachpn165/wp-docker-lemp/discussions)

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

## 🆕 Có gì mới trong `v1.0.4-beta`?

### 🧱 Refactor cấu trúc hệ thống:

- Di chuyển `nginx-proxy/` → `webserver/nginx/` để chuẩn bị hỗ trợ Caddy.
- Biến `NGINX_PROXY_DIR`, `SSL_DIR`, `PROXY_CONF_DIR`... đã được cập nhật.
- Tự động cập nhật lại mount trong `docker-compose.override.yml`.

### 🌐 Sửa lỗi & chuẩn hóa Docker network:

- Fix lỗi tên network bị sinh ngẫu nhiên do `docker compose up` trong thư mục `/tmp/`.
- Thêm `--project-name "$site_name"` vào mọi lệnh `up`/`down`.
- Tên network giờ sẽ chuẩn dạng: `tenwebsite_site_network`.

### 🧼 Cải thiện tính năng xoá website:

- Gộp câu hỏi thành một bước: **"Bạn có muốn sao lưu website trước khi xoá?"**
- Nếu chọn Yes:
  - Tự động backup `.sql` và `.tar.gz`
  - Lưu vào `archives/old_website/site-YYYYMMDD-HHMMSS`
- Sau đó xoá: thư mục site, container, volume, SSL, cronjob...

### ♻️ Thêm tính năng: Khôi phục website từ backup:

- Menu `Khôi phục website từ backup`
- Cho phép chọn website đã xoá từ thư mục lưu trữ
- Tự động giải nén mã nguồn và database
- Hướng dẫn khởi chạy lại site sau khi phục hồi

---

## 📋 Changelog (v1.0.4-beta)

```
- Refactor nginx-proxy → webserver/nginx
- Fix bug tên network khi tạo site mới
- Chuẩn hóa docker compose project-name
- Cải tiến xoá site: đơn giản, dễ hiểu, tự backup
- Tính năng mới: Khôi phục website từ thư mục backup
```

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
└── webserver/nginx/         # NGINX Proxy
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
- ♻️ Khôi phục site từ backup
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
