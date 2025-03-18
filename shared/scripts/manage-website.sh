#!/bin/bash

# Xác định thư mục chứa website
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SITES_DIR="$PROJECT_ROOT/sites"

echo -e "\033[1;33m📋 Danh sách website có thể restart:\033[0m"
ls "$SITES_DIR"
echo ""

read -p "Nhập tên website cần restart: " site_name

if [ -d "$SITES_DIR/$site_name" ]; then
    echo -e "\033[1;34m🔄 Đang khởi động lại website '$site_name'...\033[0m"
    
    # Restart container
    cd "$SITES_DIR/$site_name"
    docker-compose restart
    cd "$PROJECT_ROOT"

    echo -e "\033[1;32m✅ Website '$site_name' đã được restart thành công!\033[0m"
else
    echo -e "\033[1;31m❌ Website '$site_name' không tồn tại!\033[0m"
fi

read -p "Nhấn Enter để quay lại menu..."
