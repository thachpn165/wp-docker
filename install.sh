#!/bin/bash

# =====================================
# 🧩 install.sh – Cài đặt WP Docker LEMP từ GitHub
# =====================================

set -euo pipefail

REPO_URL="https://github.com/thachpn165/wp-docker-lemp"
BRANCH="main"
INSTALL_DIR="$HOME/wp-docker-lemp"

# 🧹 Xóa nếu thư mục đã tồn tại tạm thời
TMP_DIR="/tmp/wp-docker-install"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# 📦 Cài đặt các package cần thiết
install_dependencies() {
  echo "🔧 Đang kiểm tra và cài đặt các gói phụ thuộc..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &>/dev/null; then
      sudo apt update
      sudo apt install -y curl unzip git openssl docker.io

      # Cài Docker Compose plugin mới nhất
      if ! command -v docker compose &>/dev/null; then
        echo "🧩 Cài đặt Docker Compose (plugin)..."
        mkdir -p ~/.docker/cli-plugins/
        curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) \
          -o ~/.docker/cli-plugins/docker-compose
        chmod +x ~/.docker/cli-plugins/docker-compose
      fi

    elif command -v yum &>/dev/null; then
      sudo yum install -y curl unzip git openssl docker

      # Cài Docker Compose plugin mới nhất
      if ! command -v docker compose &>/dev/null; then
        echo "🧩 Cài đặt Docker Compose (plugin)..."
        mkdir -p ~/.docker/cli-plugins/
        curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) \
          -o ~/.docker/cli-plugins/docker-compose
        chmod +x ~/.docker/cli-plugins/docker-compose
      fi
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
      echo "🍺 Homebrew chưa được cài đặt. Vui lòng cài đặt thủ công: https://brew.sh"
      exit 1
    fi
    brew install curl unzip git openssl docker

    # Docker Desktop cho macOS đã bao gồm Docker Compose
    if ! command -v docker compose &>/dev/null; then
      echo "⚠️ Vui lòng cài Docker Desktop để sử dụng Docker Compose"
      exit 1
    fi
  else
    echo "❌ Hệ điều hành không được hỗ trợ. Chỉ hỗ trợ macOS và Linux."
    exit 1
  fi
}

install_dependencies

# 📥 Tải source từ GitHub
echo "📥 Đang tải WP Docker LEMP từ GitHub..."
curl -L "$REPO_URL/archive/refs/heads/$BRANCH.zip" -o "$TMP_DIR/source.zip"
unzip -q "$TMP_DIR/source.zip" -d "$TMP_DIR"

# 🚀 Di chuyển vào thư mục cài đặt
EXTRACTED_DIR="$TMP_DIR/wp-docker-lemp-$BRANCH"
rm -rf "$INSTALL_DIR"
mv "$EXTRACTED_DIR" "$INSTALL_DIR"

# 🔖 Ghi phiên bản hiện tại
cp "$INSTALL_DIR/version.txt" "$INSTALL_DIR/shared/VERSION"

# ✅ Hiển thị thông tin kết thúc và chạy main.sh
cd "$INSTALL_DIR"
echo -e "\n✅ Đã cài đặt thành công tại: $INSTALL_DIR"
echo -e "\n🚀 Khởi chạy trình quản lý hệ thống...\n"
bash ./shared/scripts/main.sh
