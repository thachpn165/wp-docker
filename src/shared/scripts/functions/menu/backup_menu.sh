#!/bin/bash

# === 🧠 Tự động xác định PROJECT_DIR (gốc mã nguồn) ===

if [[ -z "$PROJECT_DIR" ]]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
    while [[ "$SCRIPT_PATH" != "/" && ! -f "$SCRIPT_PATH/shared/config/config.sh" ]]; do
        SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
    done
    PROJECT_DIR="$SCRIPT_PATH"
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Không tìm thấy config.sh tại: $CONFIG_FILE" >&2
    exit 1
fi
source "$CONFIG_FILE"

# Import các hàm backup
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_actions.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_restore_web.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/schedule_backup.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/manage_cron.sh"

# Hàm hiển thị menu quản lý backup
backup_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   🛠️ QUẢN LÝ BACKUP WEBSITE   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} Sao lưu website ngay"
        echo -e "  ${GREEN}[2]${NC} Xóa backup cũ"
        echo -e "  ${GREEN}[3]${NC} Xem danh sách backup"
        echo -e "  ${GREEN}[4]${NC} Lên lịch backup tự động"
        echo -e "  ${GREEN}[5]${NC} Quản lý lịch backup (Crontab)"
        echo -e "  ${GREEN}[6]${NC} Khôi phục website từ backup"
        echo -e "  ${GREEN}[7]${NC} ❌ Thoát"
        echo -e "${BLUE}============================${NC}"
        
        read -p "🔹 Chọn một tùy chọn (1-6): " choice

        case "$choice" in
            1) backup_website ;;
            2) cleanup_old_backups ;;
            3) list_backup_files ;;
            4) schedule_backup_create ;;
            5) manage_cron_menu ;;
            6) backup_restore_web ;;
            7) 
                echo -e "${GREEN}👋 Thoát khỏi menu Backup!${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Lựa chọn không hợp lệ, vui lòng nhập lại!${NC}"
                ;;
        esac
    done
}
