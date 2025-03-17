#!/bin/bash

# Xác định thư mục gốc của dự án (dù user chạy script từ đâu)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/shared/scripts"

# Màu sắc terminal
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Biểu tượng Unicode
ARROW="\xE2\x96\xB6"

# Kiểm tra Docker có đang chạy không
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}⚠️ Docker chưa chạy! Vui lòng khởi động Docker trước khi sử dụng.${NC}"
    exit 1
fi

# Hàm hiển thị tiêu đề
print_header() {
    echo -e "${MAGENTA}==============================================${NC}"
    echo -e "${MAGENTA}        🚀 ${CYAN}WordPress Docker LEMP Stack 🚀        ${NC}"
    echo -e "${MAGENTA}==============================================${NC}"
}

# Hiển thị menu chính
while true; do
    clear
    print_header
    echo -e "${BLUE}MENU CHÍNH:${NC}"
    echo -e "  ${GREEN}[1]${NC} 🌍 Quản lý Website WordPress"
    echo -e "  ${GREEN}[2]${NC} 🔐 Quản lý Chứng Chỉ SSL"
    echo -e "  ${GREEN}[3]${NC} ⚙️ Công Cụ Hệ Thống"
    echo -e "  ${GREEN}[4]${NC} ❌ Thoát"
    echo ""
    
    read -p "Vui lòng chọn một chức năng (1-4): " choice

    case $choice in
        1) 
            while true; do
                clear
                echo -e "${YELLOW}===== QUẢN LÝ WEBSITE WORDPRESS =====${NC}"
                echo -e "${GREEN}[1]${NC} ➕ Tạo Website Mới"
                echo -e "${GREEN}[2]${NC} 🗑️ Xóa Website"
                echo -e "${GREEN}[3]${NC} 📋 Danh Sách Website"
                echo -e "${GREEN}[4]${NC} 🔄 Restart Website"
                echo -e "${GREEN}[5]${NC} 📄 Xem Logs Website"
                echo -e "${GREEN}[6]${NC} ⬅️ Quay lại"
                echo ""
                read -p "Vui lòng chọn một chức năng (1-6): " sub_choice

                case $sub_choice in
                    1) bash "$SCRIPTS_DIR/create-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
                    2) bash "$SCRIPTS_DIR/delete-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
                    3) bash "$SCRIPTS_DIR/list-websites.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
                    4) bash "$SCRIPTS_DIR/restart-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
                    5) bash "$SCRIPTS_DIR/logs-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
                    6) break ;;
                    *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}" && sleep 2 ;;
                esac
            done
        ;;
        4) echo -e "${GREEN}❌ Thoát chương trình.${NC}" && exit 0 ;;
        *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ.${NC}" && sleep 2 ;;
    esac
done
