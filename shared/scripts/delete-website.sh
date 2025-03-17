#!/bin/bash

# Xác định thư mục chứa website
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SITES_DIR="$PROJECT_ROOT/sites"
PROXY_SCRIPT="$PROJECT_ROOT/nginx-proxy/restart-nginx-proxy.sh"

echo -e "\033[1;33m📋 Danh sách các website có thể xóa:\033[0m"
ls "$SITES_DIR"
echo ""

read -p "Nhập tên website cần xóa: " site_name

if [ -d "$SITES_DIR/$site_name" ]; then
    echo -e "\033[1;31m⚠️ Bạn có chắc muốn xóa website '$site_name'? (y/n): \033[0m"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\033[1;34m🔄 Đang xóa website '$site_name'...\033[0m"
        
        # Dừng & xóa container
        cd "$SITES_DIR/$site_name"
        docker-compose down
        cd "$PROJECT_ROOT"

        # Xóa thư mục
        rm -rf "$SITES_DIR/$site_name"
        echo -e "\033[1;32m✅ Website '$site_name' đã bị xóa thành công!\033[0m"
        # Reload NGINX Proxy để xóa cấu hình website đã bị xóa
        if [ -f "$PROXY_SCRIPT" ]; then
            bash "$PROXY_SCRIPT"
        else
            echo -e "${RED}⚠️ Không tìm thấy tập tin $PROXY_SCRIPT. Hãy kiểm tra lại.${NC}"
        fi
    else
        echo -e "\033[1;33m⚠️ Hủy thao tác xóa website '$site_name'.\033[0m"
    fi
else
    echo -e "\033[1;31m❌ Website '$site_name' không tồn tại!\033[0m"
fi


read -p "Nhấn Enter để quay lại menu..."
