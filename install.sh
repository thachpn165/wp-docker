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

  # Kiểm tra docker
  if command -v docker &>/dev/null; then
    echo "✅ Đã có Docker"
  else
    echo "❌ Docker chưa được cài, đang tiến hành cài đặt..."
    if command -v apt &>/dev/null; then
      sudo apt update
      sudo apt install -y docker.io
    elif command -v yum &>/dev/null; then
      sudo yum install -y docker
    fi
  fi

  # Kiểm tra docker compose plugin
  if docker compose version &>/dev/null; then
    echo "✅ Đã có Docker Compose (plugin)"
  else
    echo "❌ Docker Compose plugin chưa có, đang tiến hành cài đặt..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    curl -SL "https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-${OS}-${ARCH}" \
      -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
    chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
    echo "✅ Đã cài Docker Compose plugin vào $DOCKER_CONFIG/cli-plugins"
  fi

  # Các gói cơ bản khác
  for pkg in curl unzip git openssl; do
    if ! command -v $pkg &>/dev/null; then
      echo "❌ Gói $pkg chưa có, đang tiến hành cài đặt..."
      if command -v apt &>/dev/null; then
        sudo apt install -y $pkg
      elif command -v yum &>/dev/null; then
        sudo yum install -y $pkg
      fi
    else
      echo "✅ Đã có $pkg"
    fi
  done

  # Đặc biệt với macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
      echo "🍺 Homebrew chưa được cài đặt. Vui lòng cài đặt tại: https://brew.sh"
      exit 1
    fi
    echo "✅ Hệ điều hành macOS - đang kiểm tra Docker Desktop..."
    if ! docker compose version &>/dev/null; then
      echo "⚠️ Vui lòng cài Docker Desktop để sử dụng Docker Compose trên macOS"
      exit 1
    fi
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