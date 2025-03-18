#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Xác định đường dẫn tuyệt đối của `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# **Chạy setup hệ thống trước khi hiển thị menu**
bash "$SCRIPTS_DIR/setup-system.sh"

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

# **Hàm hiển thị tiêu đề**
print_header() {
    echo -e "${MAGENTA}==============================================${NC}"
    echo -e "${MAGENTA}        🚀 ${CYAN}WordPress Docker LEMP Stack 🚀        ${NC}"
    echo -e "${MAGENTA}==============================================${NC}"
    echo -e "${BLUE}🔍 Kiểm tra hệ thống...${NC}"

    # Hiển thị trạng thái hệ thống
    if is_docker_running; then
        echo -e "${GREEN}✅ Docker đang chạy${NC}"
    else
        echo -e "${RED}❌ Docker không chạy!${NC}"
    fi

    if is_network_exists "$DOCKER_NETWORK"; then
        echo -e "${GREEN}✅ Mạng '$DOCKER_NETWORK' đã tồn tại${NC}"
    else
        echo -e "${RED}❌ Mạng '$DOCKER_NETWORK' chưa được tạo!${NC}"
    fi

    if is_container_running "$NGINX_PROXY_CONTAINER"; then
        echo -e "${GREEN}✅ NGINX Proxy đang chạy${NC}"
    else
        echo -e "${RED}❌ NGINX Proxy không chạy!${NC}"
    fi
}

# **Hiển thị menu quản lý website**
manage_website_menu() {
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

        read -p "Chọn một chức năng (1-6): " sub_choice
        case $sub_choice in
            1) bash "$WEBSITE_MGMT_DIR/create-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            2) bash "$WEBSITE_MGMT_DIR/delete-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            3) bash "$WEBSITE_MGMT_DIR/list-websites.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            4) bash "$WEBSITE_MGMT_DIR/restart-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            5) bash "$WEBSITE_MGMT_DIR/logs-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            6) break ;;
            *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}" && sleep 2 ;;
        esac
    done
}

# **Hiển thị menu chính**
while true; do
    clear
    print_header
    echo -e "${BLUE}MENU CHÍNH:${NC}"
    echo -e "  ${GREEN}[1]${NC} 🌍 Quản lý Website WordPress"
    echo -e "  ${GREEN}[2]${NC} 🔐 Quản lý Chứng Chỉ SSL"
    echo -e "  ${GREEN}[3]${NC} ⚙️ Công Cụ Hệ Thống"
    echo -e "  ${GREEN}[4]${NC} ❌ Thoát"
    echo ""

    read -p "Chọn một chức năng (1-4): " choice
    case $choice in
        1) manage_website_menu ;;
        2) manage_ssl_menu ;;
        3) system_tools_menu ;;
        4) echo -e "${GREEN}❌ Thoát chương trình.${NC}" && exit 0 ;;
        *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ.${NC}" && sleep 2 ;;
    esac
done
