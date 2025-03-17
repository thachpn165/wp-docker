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
CHECK_MARK="\xE2\x9C\x94"
ARROW="\xE2\x96\xB6"

# Kiểm tra hệ điều hành
OS_TYPE=$(uname -s)

# Lấy thông tin CPU
if [[ "$OS_TYPE" == "Linux" ]]; then
    cpu_cores=$(nproc)
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    cpu_cores=$(sysctl -n hw.ncpu)
else
    cpu_cores="N/A"
fi

# Lấy thông tin RAM
if [[ "$OS_TYPE" == "Linux" ]]; then
    total_ram=$(awk '/MemTotal/ {print $2/1024 " MB"}' /proc/meminfo)
    free_ram=$(awk '/MemAvailable/ {print $2/1024 " MB"}' /proc/meminfo)
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    total_ram=$(sysctl -n hw.memsize | awk '{print $1/1024/1024 " MB"}')
    free_ram="Không khả dụng trên macOS"
else
    total_ram="N/A"
    free_ram="N/A"
fi

# Lấy thông tin dung lượng ổ cứng
if [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "Darwin" ]]; then
    disk_space=$(df -h / | awk 'NR==2 {print $4}')
else
    disk_space="N/A"
fi

# Lấy phiên bản Docker
docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')

# Kiểm tra Docker có đang chạy không
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}⚠️ Docker chưa chạy! Vui lòng khởi động Docker trước khi sử dụng.${NC}"
    exit 1
fi

# Hàm hiển thị tiêu đề lung linh
print_header() {
    echo -e "${MAGENTA}==============================================${NC}"
    echo -e "${MAGENTA}        🚀 ${CYAN}WordPress Docker LEMP Stack 🚀        ${NC}"
    echo -e "${MAGENTA}==============================================${NC}"
}

# Hiển thị thông tin hệ thống
show_system_info() {
    echo -e "${YELLOW}${ARROW} Hệ điều hành: ${WHITE}$OS_TYPE${NC}"
    echo -e "${YELLOW}${ARROW} CPU Cores: ${WHITE}$cpu_cores${NC}"
    echo -e "${YELLOW}${ARROW} Tổng RAM: ${WHITE}$total_ram${NC}"
    echo -e "${YELLOW}${ARROW} RAM trống: ${WHITE}$free_ram${NC}"
    echo -e "${YELLOW}${ARROW} Ổ cứng trống: ${WHITE}$disk_space${NC}"
    echo -e "${YELLOW}${ARROW} Docker Version: ${WHITE}$docker_version${NC}"
    echo ""
}

# Hiển thị menu chính
while true; do
    clear
    print_header
    show_system_info

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
                    1) bash "$SCRIPTS_DIR/create-website.sh" ;;
                    2) bash "$SCRIPTS_DIR/delete-website.sh" ;;
                    3) bash "$SCRIPTS_DIR/list-websites.sh" ;;
                    4) bash "$SCRIPTS_DIR/restart-website.sh" ;;
                    5) bash "$SCRIPTS_DIR/logs-website.sh" ;;
                    6) break ;;
                    *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}" && sleep 2 ;;
                esac
            done
        ;;
        4) echo -e "${GREEN}❌ Thoát chương trình.${NC}" && exit 0 ;;
        *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ.${NC}" && sleep 2 ;;
    esac
done
