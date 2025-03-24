#!/bin/bash

# =====================================
# 🧩 install.sh – Cài đặt WP Docker LEMP từ GitHub
# =====================================

set -euo pipefail
REPO_URL="https://github.com/your-username/wp-docker-lemp"
BRANCH="main"
INSTALL_DIR="$HOME/wp-docker-lemp"

# 🧹 Xóa nếu thư mục đã tồn tại tạm thời
TMP_DIR="/tmp/wp-docker-install"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

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

# ⚙️ Chạy thiết lập hệ thống ban đầu
cd "$INSTALL_DIR"
bash shared/scripts/system-setup.sh

echo -e "\n✅ Đã cài đặt thành công tại: $INSTALL_DIR"
