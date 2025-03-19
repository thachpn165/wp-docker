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
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/utils.sh"

# Hàm hiển thị menu quản lý backup
backup_menu() {
    while true; do
        echo "============================"
        echo "   🛠️ QUẢN LÝ BACKUP WEBSITE   "
        echo "============================"
        echo "1️⃣ Sao lưu website ngay"
        echo "2️⃣ Xóa backup cũ"
        echo "3️⃣ Xem danh sách backup"
        echo "4️⃣ Thoát"
        echo "============================"
        read -p "🔹 Chọn chức năng: " choice

        case "$choice" in
            1) backup_website ;;
            2) cleanup_old_backups ;;
            3) list_backup_files ;;
            4) 
                echo "👋 Thoát khỏi menu Backup!"
                break
                ;;
            *)
                echo "❌ Lựa chọn không hợp lệ, vui lòng nhập lại!"
                ;;
        esac
    done
}
