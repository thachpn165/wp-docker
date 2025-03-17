#!/bin/bash

# Xác định thư mục gốc của dự án (dù user chạy script từ đâu)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/shared/scripts"

# Kiểm tra Docker có đang chạy không
if ! docker info >/dev/null 2>&1; then
    echo -e "\033[1;31m⚠️ Docker chưa chạy! Vui lòng khởi động Docker trước khi sử dụng.\033[0m"
    exit 1
fi

# Hàm hiển thị tiêu đề lung linh
print_header() {
    echo -e "\033[1;35m==============================================\033[0m"
    echo -e "\033[1;35m        🚀 WordPress Docker LEMP Stack 🚀        \033[0m"
    echo -e "\033[1;35m==============================================\033[0m"
}

# Hiển thị menu
while true; do
    clear
    print_header
    echo -e "\033[1;34m[1]\033[0m 🌍 Quản lý Website WordPress"
    echo -e "\033[1;34m[2]\033[0m 🔐 Quản lý Chứng Chỉ SSL"
    echo -e "\033[1;34m[3]\033[0m ⚙️ Công Cụ Hệ Thống"
    echo -e "\033[1;34m[4]\033[0m ❌ Thoát"
    echo ""
    read -p "Vui lòng chọn một chức năng (1-4): " choice

    case $choice in
        1) 
            while true; do
                clear
                echo -e "\033[1;33m===== QUẢN LÝ WEBSITE WORDPRESS =====\033[0m"
                echo -e "\033[1;32m[1]\033[0m ➕ Tạo Website Mới"
                echo -e "\033[1;32m[2]\033[0m 🗑️ Xóa Website"
                echo -e "\033[1;32m[3]\033[0m 📋 Danh Sách Website"
                echo -e "\033[1;32m[4]\033[0m 🔄 Restart Website"
                echo -e "\033[1;32m[5]\033[0m 📄 Xem Logs Website"
                echo -e "\033[1;32m[6]\033[0m ⬅️ Quay lại"
                echo ""
                read -p "Vui lòng chọn một chức năng (1-6): " sub_choice

                case $sub_choice in
                    1) bash "$SCRIPTS_DIR/create-website.sh" ;;
                    2) bash "$SCRIPTS_DIR/delete-website.sh" ;;
                    3) bash "$SCRIPTS_DIR/list-websites.sh" ;;
                    4) bash "$SCRIPTS_DIR/restart-website.sh" ;;
                    5) bash "$SCRIPTS_DIR/logs-website.sh" ;;
                    6) break ;;
                    *) echo -e "\033[1;31m⚠️ Lựa chọn không hợp lệ!\033[0m" && sleep 2 ;;
                esac
            done
        ;;
        4) echo -e "\033[1;32m❌ Thoát chương trình.\033[0m" && exit 0 ;;
        *) echo -e "\033[1;31m⚠️ Lựa chọn không hợp lệ.\033[0m" && sleep 2 ;;
    esac
done
