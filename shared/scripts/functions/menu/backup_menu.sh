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

# Import các hàm backup
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_actions.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/schedule_backup.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/manage_cron.sh"

# Hàm hiển thị menu quản lý backup
backup_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   🛠️ QUẢN LÝ BACKUP WEBSITE   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} 🔄 Sao lưu website ngay"
        echo -e "  ${GREEN}[2]${NC} 🗑️ Xóa backup cũ"
        echo -e "  ${GREEN}[3]${NC} 📂 Xem danh sách backup"
        echo -e "  ${GREEN}[4]${NC} ⏳ Lên lịch backup tự động"
        echo -e "  ${GREEN}[5]${NC} ⚙️ Quản lý lịch backup (Crontab)"
        echo -e "  ${GREEN}[6]${NC} ❌ Thoát"
        echo -e "${BLUE}============================${NC}"
        
        read -p "🔹 Chọn một tùy chọn (1-6): " choice

        case "$choice" in
            1) backup_website ;;
            2) cleanup_old_backups ;;
            3) list_backup_files ;;
            4) schedule_backup_create ;;
            5) manage_cron_menu ;;
            6) 
                echo -e "${GREEN}👋 Thoát khỏi menu Backup!${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Lựa chọn không hợp lệ, vui lòng nhập lại!${NC}"
                ;;
        esac
    done
}
