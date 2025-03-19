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

# Import các hàm từ backup-utils
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_actions.sh"


backup_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   🛠️ QUẢN LÝ BACKUP WEBSITE   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} 🔄 Sao lưu website ngay"
        echo -e "  ${GREEN}[2]${NC} 🗑️ Xóa backup cũ"
        echo -e "  ${GREEN}[3]${NC} 📂 Xem danh sách backup"
        echo -e "  ${GREEN}[4]${NC} ❌ Thoát"
        echo -e "${BLUE}============================${NC}"
        
        read -p "🔹 Chọn chức năng: " choice

        case "$choice" in
            1) backup_website ;;
            2) cleanup_old_backups ;;
            3) list_backup_files ;;
            4) 
                echo -e "${GREEN}👋 Thoát khỏi menu Backup!${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Lựa chọn không hợp lệ, vui lòng nhập lại!${NC}"
                ;;
        esac
    done
}

