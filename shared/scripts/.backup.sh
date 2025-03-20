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
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_database.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_files.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"

# Định nghĩa biến (ví dụ cho site example.com)
SITE_NAME="wpdock"
DB_NAME="wordpress"
DB_USER="root"
DB_PASS="eCGWSgtJiPWmhWYK"
WEB_ROOT="$SITES_DIR/$SITE_NAME/wordpress"
RETENTION_DAYS=2  # Giữ lại backup trong 7 ngày

# Thực hiện backup
#backup_database "$SITE_NAME" "$DB_NAME" "$DB_USER" "$DB_PASS"
#backup_files "$SITE_NAME" "$WEB_ROOT"
cleanup_backups "$SITE_NAME" "$RETENTION_DAYS"