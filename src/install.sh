#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
BIN_NAME="wpdocker"
BIN_LINK="/usr/local/bin/$BIN_NAME"
REPO_URL="https://github.com/thachpn165/wp-docker"
ZIP_NAME="wp-docker.zip"
DEV_MODE=false

# ========================
# 🧩 Hàm cài đặt dependencies
# ========================
install_dependencies() {
  echo "📦 Đang kiểm tra và cài đặt dependencies..."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v docker &>/dev/null; then
      echo "⚠️ Docker chưa được cài. Vui lòng cài Docker Desktop tại: https://www.docker.com/products/docker-desktop/"
    fi
    if ! command -v unzip &>/dev/null; then
      brew install unzip
    fi
    if ! command -v composer &>/dev/null; then
      brew install composer
    fi
  else
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install -y curl unzip docker.io composer
    elif command -v yum &>/dev/null; then
      sudo yum install -y curl unzip docker composer
    fi
  fi
}

# ========================
# ⚙️ Xử lý tham số dòng lệnh
# ========================
if [[ "$1" == "--dev" ]]; then
  DEV_MODE=true
  echo "🛠 Đang cài đặt ở chế độ DEV (không tạo symlink hệ thống)"
fi

# ========================
# ✅ Kiểm tra công cụ bắt buộc
# ========================
install_dependencies

for cmd in curl unzip docker composer; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Thiếu chương trình: $cmd. Vui lòng cài đặt trước."
    exit 1
  fi
done

if ! docker compose version >/dev/null 2>&1; then
  echo "❌ Docker Compose plugin chưa được cài hoặc không khả dụng."
  exit 1
fi

# ========================
# 🧹 Kiểm tra nếu thư mục đã tồn tại
# ========================
if [[ -d "$INSTALL_DIR" ]]; then
  echo "⚠️ Thư mục $INSTALL_DIR đã tồn tại."
  read -rp "❓ Bạn có muốn xoá và cài đè lên không? [y/N]: " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Huỷ cài đặt."
    exit 0
  fi
  sudo rm -rf "$INSTALL_DIR"
fi

# ========================
# 📥 Tải và giải nén release
# ========================
echo "📦 Đang tải mã nguồn từ GitHub Release..."
curl -L "$REPO_URL/releases/latest/download/wp-docker.zip" -o "$ZIP_NAME"

echo "📁 Đang giải nén vào $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo unzip -q "$ZIP_NAME" -d "$INSTALL_DIR"
rm "$ZIP_NAME"

# ========================
# ✅ Cấp quyền cho user hiện tại
# ========================
echo "🔐 Cấp quyền sử dụng cho user: $USER"
sudo chown -R "$USER" "$INSTALL_DIR"

# ========================
# 🔗 Tạo alias toàn cục nếu không phải chế độ dev
# ========================
chmod +x "$INSTALL_DIR/shared/bin/$BIN_NAME.sh"

if [[ "$DEV_MODE" != true ]]; then
  sudo ln -sf "$INSTALL_DIR/shared/bin/$BIN_NAME.sh" "$BIN_LINK"
  echo "✅ Đã tạo lệnh '$BIN_NAME' để chạy từ bất kỳ đâu."
fi

echo "✅ Cài đặt thành công tại: $INSTALL_DIR"
echo "👉 Bạn có thể chạy hệ thống bằng lệnh: $BIN_NAME"
