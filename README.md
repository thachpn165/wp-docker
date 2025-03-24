# 🚀 WP Docker LEMP Stack

[![Phiên bản](https://img.shields.io/badge/version-v1.0.1_beta-blue)](https://github.com/thachpn165/wp-lemp-docker/releases)
[![Docker Support](https://img.shields.io/badge/docker-ready-blue)](https://www.docker.com/)
[![macOS & Linux](https://img.shields.io/badge/os-macOS%20%7C%20Linux-green)](https://github.com/thachpn165/wp-lemp-docker/)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker-lemp)](./LICENSE)
[![Made with ❤️](https://img.shields.io/badge/made%20with-%E2%9D%A4-red)](https://github.com/thachpn165/wp-lemp-docker/)

---

## 📝 Giới thiệu

**WP Docker LEMP Stack** là một hệ thống quản lý WordPress hoàn chỉnh chạy bằng Docker, hỗ trợ nhiều website, tích hợp SSL, backup tự động, rclone upload, WP-CLI, hệ thống log và nhiều tiện ích nâng cao khác.

Dự án hướng tới sự **đơn giản, dễ dùng, dễ mở rộng** và tương thích hoàn hảo trên **macOS** & **Linux**. Tất cả đều quản lý thông qua một giao diện terminal dạng menu thân thiện.

---

## 🌟 Mục tiêu dự án

- ✅ Quản lý nhiều website WordPress trong cùng 1 server Docker
- ✅ Cài đặt nhanh chóng với Docker & Docker Compose
- ✅ Tích hợp SSL miễn phí (Let's Encrypt) và chứng chỉ thủ công
- ✅ Tự động backup và upload lên cloud (Google Drive, OneDrive…)
- ✅ Quản lý cronjob backup trực tiếp từ terminal
- ✅ Hệ thống file script module hoá rõ ràng, dễ bảo trì & mở rộng
- ✅ Giao diện menu trực quan, phù hợp cho cả người không chuyên

---

## 🧱\ Cấu trúc hệ thống

```bash
.
├── install.sh               # Cài đặt hệ thống tự động
├── update.sh                # Cập nhật source mới nhất từ GitHub
├── uninstall.sh             # Gỡ toàn bộ hệ thống
├── shared/
│   ├── bin/wp               # WP-CLI binary
│   ├── config/config.sh     # Biến cấu hình toàn cục
│   └── scripts/functions/   # Các module chức năng chia theo nhóm
├── sites/                   # Nơi chứa các site WordPress
│   └── ten_website/
│       ├── wordpress/       # Mã nguồn WP
│       ├── logs/            # Log backup, log hệ thống
│       ├── backups/         # File backup
│       ├── php/             # PHP container
│       └── mariadb/         # Database container
└── nginx-proxy/             # NGINX Proxy chung
    ├── conf.d/              # Cấu hình từng website
    ├── ssl/                 # Chứng chỉ SSL
    └── globals/             # Global config, cache, waf, nginx.conf
```

---

## ⚙️ Yêu cầu hệ thống

- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0
- **macOS hoặc Linux** (Debian/Ubuntu/CentOS)
- **Không cần GUI, hoạt động hoàn toàn trong terminal**

---

## 🚀 Hướng dẫn cài đặt

```bash
curl -Lso- https://raw.githubusercontent.com/thachpn165/wp-docker-lemp/refs/heads/main/install.sh | bash
```

> Hoặc clone thủ công:

```bash
git clone https://github.com/thachpn165/wp-docker-lemp
cd wp-docker
chmod +x install.sh && ./install.sh
```

---

## 🧑‍💻 Hướng dẫn sử dụng

Sau khi cài đặt, bạn có thể chạy:

```bash
cd wp-docker-lemp
chmod +x main.sh
bash main.sh
```

### Các tính năng chính:

- 🔧 Tạo website WordPress mới
- 🌐 Gắn tên miền và tự động cấu hình NGINX
- 🔐 Cài SSL (tự ký, thủ công, Let's Encrypt)
- 📂 Tự động backup mã nguồn + database
- ☁️ Upload backup lên cloud (qua Rclone)
- 🗓 Lên lịch backup tự động (Crontab)
- 🔍 Kiểm tra thông tin SSL, quản lý WP-CLI...

---

## ☁️ Backup & Rclone

- Hỗ trợ upload backup qua các cloud như:
  - Google Drive
  - OneDrive
  - Dropbox
  - Mega.nz
- Cài đặt nhanh với:
```bash
./shared/scripts/functions/rclone/setup_rclone.sh
```

---

## 📦 Cập nhật hệ thống

Để kiểm tra và cập nhật phiên bản mới:

```bash
./update.sh
```

Hoặc hệ thống sẽ tự kiểm tra phiên bản mới khi khởi động `main.sh`.

---

## 👥 Đóng góp & phát triển

Chúng tôi luôn hoan nghênh sự đóng góp!

### 💠 Cách tham gia:
1. Fork repository này
2. Tạo nhánh mới từ `main`
3. Commit & push các thay đổi
4. Gửi pull request với mô tả chi tiết

### 📋 Góp ý / Báo lỗi:
- Mở issue trên GitHub

---

## 📃 Giấy phép

Dự án được phát hành theo [MIT License](./LICENSE)

---