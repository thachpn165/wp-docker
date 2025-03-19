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

# Import các hàm Backup & Cleanup
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_database.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_files.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"

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
            1)
                read -p "Nhập tên website: " SITE_NAME
                read -p "Nhập tên database: " DB_NAME
                read -p "Nhập user database: " DB_USER
                read -s -p "Nhập mật khẩu database: " DB_PASS
                echo ""
                read -p "Nhập thư mục gốc website (VD: /var/www/example.com): " WEB_ROOT

                backup_database "$SITE_NAME" "$DB_NAME" "$DB_USER" "$DB_PASS"
                backup_files "$SITE_NAME" "$WEB_ROOT"
                ;;
            2)
                read -p "Nhập tên website để dọn dẹp backup: " SITE_NAME
                read -p "Giữ lại backup trong bao nhiêu ngày? (VD: 7): " RETENTION_DAYS
                cleanup_backups "$SITE_NAME" "$RETENTION_DAYS"
                ;;
            3)
                read -p "Nhập tên website: " SITE_NAME
                ls -lh "$SITES_DIR/$SITE_NAME/backups/"
                ;;
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
