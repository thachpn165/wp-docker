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

# Import menu functions
source "$(dirname "$0")/shared/scripts/functions/menu/menu_utils.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/manage_website_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/wordpress_tools_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/system_tools_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/backup_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/rclone_menu.sh"

# **Chạy setup hệ thống trước khi hiển thị menu**
bash "$SCRIPTS_DIR/setup-system.sh"

# ✔️ ❌ **Biểu tượng trạng thái**
CHECKMARK="${GREEN}✅${NC}"
CROSSMARK="${RED}❌${NC}"

# 🏆 **Hiển thị tiêu đề**
print_header() {
    echo -e "\n\n\n"
    get_system_info
    echo -e "${MAGENTA}==============================================${NC}"
    echo -e "${MAGENTA}        🚀 ${CYAN}WordPress Docker LEMP Stack 🚀        ${NC}"
    echo -e "${MAGENTA}==============================================${NC}"
    echo ""
    echo -e "${BLUE}🐳 Trạng thái Docker:${NC}"
    echo -e "  🌐 Docker Network: $(check_docker_network)"
    echo -e "  🚀 NGINX Proxy: $(check_nginx_status)"

    echo ""
    echo -e "${BLUE}📊 Thông tin hệ thống:${NC}"
    echo -e "  🖥  CPU: ${GREEN}${CPU_MODEL} (${TOTAL_CPU} cores)${NC}"
    echo -e "  💾 RAM: ${YELLOW}${USED_RAM}MB / ${TOTAL_RAM}MB${NC}"
    echo -e "  📀 Disk: ${YELLOW}${DISK_USAGE}${NC}"
    echo -e "  🌍 IP Address: ${CYAN}${IP_ADDRESS}${NC}"
    echo -e "${MAGENTA}==============================================${NC}"
}

# 🎯 **Hiển thị menu chính**
while true; do
    print_header
    echo -e "${BLUE}MENU CHÍNH:${NC}"
    echo -e "  ${GREEN}[1]${NC} 🌍 Quản lý Website WordPress     ${GREEN}[5]${NC} 🛠️ Tiện ích WordPress"
    echo -e "  ${GREEN}[2]${NC} 🔐 Quản lý Chứng Chỉ SSL         ${GREEN}[6]${NC} 🔄 Quản lý Backup Website"
    echo -e "  ${GREEN}[3]${NC} ⚙️ Công Cụ Hệ Thống               ${GREEN}[7]${NC} ⚡ Quản lý Cache WordPress"
    echo -e "  ${GREEN}[4]${NC} 📤 Quản lý Rclone                 ${GREEN}[8]${NC} ❌ Thoát"
    echo ""

    read -p "🔹 Chọn một tùy chọn (1-9): " choice
    case "$choice" in
        1) manage_website_menu ;;
        2) manage_ssl_menu ;;
        3) system_tools_menu ;;
        4) rclone_menu ;;
        5) wordpress_tools_menu ;;
        6) backup_menu ;;
        7) bash "$SCRIPTS_DIR/setup-cache.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
        9) echo -e "${GREEN}❌ Thoát chương trình.${NC}" && exit 0 ;;
        *) 
            echo -e "${RED}⚠️ Lựa chọn không hợp lệ! Vui lòng chọn từ [1-9].${NC}"
            sleep 2 
            ;;
    esac
done
