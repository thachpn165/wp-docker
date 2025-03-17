#!/bin/bash

# Xác định thư mục chứa website
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SITES_DIR="$PROJECT_ROOT/sites"

echo -e "\033[1;33m📋 Danh sách website có thể xem logs:\033[0m"
ls "$SITES_DIR"
echo ""

read -p "Nhập tên website cần xem logs: " site_name

if [ -d "$SITES_DIR/$site_name" ]; then
    echo -e "\033[1;34m📄 Hiển thị logs của website '$site_name'...\033[0m"
    
    cd "$SITES_DIR/$site_name"
    docker-compose logs --tail=50 --follow

    echo -e "\033[1;33m⚠️ Kết thúc logs, quay lại menu chính.\033[0m"
else
    echo -e "\033[1;31m❌ Website '$site_name' không tồn tại!\033[0m"
fi

read -p "Nhấn Enter để quay lại menu..."
