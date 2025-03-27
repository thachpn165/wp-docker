#!/bin/bash

# === 🧠 Tự động xác định PROJECT_DIR (gốc mã nguồn) ===

if [[ -z "$PROJECT_DIR" ]]; then
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
PROJECT_DIR="$SCRIPT_PATH"

break
fi
SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
fi

  

# === ✅ Load config.sh từ PROJECT_DIR ===

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
echo "❌ Không tìm thấy config.sh tại: $CONFIG_FILE" >&2
exit 1
fi
source "$CONFIG_FILE"

# Import menu functions
source "$(dirname "$0")/shared/scripts/functions/menu/menu_utils.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/website_management_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/wordpress_tools_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/system_tools_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/backup_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/rclone_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/ssl_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/menu/php_menu.sh"
source "$(dirname "$0")/shared/scripts/functions/core/core_version_management.sh"
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
    echo ""
    # **Hiển thị phiên bản hiện tại và phiên bản mới nhất**
    core_display_version

    echo -e "${MAGENTA}==============================================${NC}"
}

# 🎯 **Hiển thị menu chính**
while true; do
    core_check_for_update
    print_header
    echo -e "${BLUE}MENU CHÍNH:${NC}"
    echo -e "  ${GREEN}[1]${NC} Quản lý Website WordPress     ${GREEN}[5]${NC} Tiện ích WordPress"
    echo -e "  ${GREEN}[2]${NC} Quản lý Chứng Chỉ SSL         ${GREEN}[6]${NC} Quản lý Backup Website"
    echo -e "  ${GREEN}[3]${NC} Công Cụ Hệ Thống              ${GREEN}[7]${NC} Quản lý Cache WordPress"
    echo -e "  ${GREEN}[4]${NC} Quản lý Rclone                ${GREEN}[8]${NC} Quản lý PHP"
    echo -e "  ${GREEN}[9]${NC} Cập nhật hệ thống             ${GREEN}[10]${NC} ❌ Thoát"
    echo ""

    read -p "🔹 Chọn một tùy chọn (1-10): " choice
    case "$choice" in
        1) website_management_menu ;;
        2) ssl_menu ;;
        3) system_tools_menu ;;
        4) rclone_menu ;;
        5) wordpress_tools_menu ;;
        6) backup_menu ;;
        7) bash "$SCRIPTS_DIR/setup-cache.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
        8) php_menu ;;
        9) core_check_version_update ;;  # Gọi hàm hiển thị phiên bản và cập nhật
        10) echo -e "${GREEN}❌ Thoát chương trình.${NC}" && exit 0 ;;
        *) 
            echo -e "${RED}⚠️ Lựa chọn không hợp lệ! Vui lòng chọn từ [1-10].${NC}"
            sleep 2 
            ;;
    esac
done
