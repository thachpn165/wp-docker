#!/bin/bash

# =====================================
# 🧼 uninstall.sh – Gỡ cài đặt WP Docker LEMP
# =====================================

set -euo pipefail
INSTALL_DIR="$HOME/wp-docker-lemp"
REPO_URL="https://github.com/your-username/wp-docker-lemp"
REPO_RAW="https://raw.githubusercontent.com/your-username/wp-docker-lemp"

# 🔒 Xác nhận xoá hệ thống
read -p "⚠️ Bạn có chắc chắn muốn gỡ cài đặt toàn bộ WP Docker LEMP? [y/N]: " confirm
confirm=${confirm,,}  # lowercase

if [[ "$confirm" != "y" ]]; then
    echo "❌ Hủy thao tác gỡ cài đặt."
    exit 0
fi

# 🛑 Dừng toàn bộ container nếu đang chạy
if [ -d "$INSTALL_DIR/sites" ]; then
    for site_dir in "$INSTALL_DIR/sites"/*; do
        if [ -f "$site_dir/docker-compose.yml" ]; then
            echo "🛑 Dừng website: $(basename "$site_dir")"
            (cd "$site_dir" && docker compose down) || true
        fi
    done
fi

# 🛑 Dừng nginx-proxy nếu đang chạy
if docker ps --format '{{.Names}}' | grep -q nginx-proxy; then
    echo "🛑 Dừng nginx-proxy..."
    (cd "$INSTALL_DIR/nginx-proxy" && docker compose down) || true
fi

# 🧹 Xoá thư mục cài đặt
rm -rf "$INSTALL_DIR"
echo "✅ Đã xoá thư mục: $INSTALL_DIR"

# 🧹 Xoá file log nếu muốn
read -p "🗑️ Bạn có muốn xoá thư mục logs? ($INSTALL_DIR/logs)? [y/N]: " remove_logs
remove_logs=${remove_logs,,}
if [[ "$remove_logs" == "y" ]]; then
    rm -rf "$INSTALL_DIR/logs"
    echo "✅ Đã xoá logs."
fi

echo -e "\n✅ Đã gỡ cài đặt WP Docker LEMP thành công."