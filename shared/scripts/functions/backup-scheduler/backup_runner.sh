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
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_actions.sh"

# Nhận tham số từ crontab (tên website)
SITE_NAME="$1"

if [[ -z "$SITE_NAME" ]]; then
    echo "❌ Lỗi: Thiếu tham số SITE_NAME!" >&2
    exit 1
fi

LOG_DIR="$SITES_DIR/$SITE_NAME/logs"
LOG_FILE="$LOG_DIR/wp-backup.log"

is_directory_exist "$LOG_DIR"

echo "------------------------------------" >> "$LOG_FILE"
echo "📅 $(date '+%Y-%m-%d %H:%M:%S') - BẮT ĐẦU BACKUP $SITE_NAME" >> "$LOG_FILE"

# Tìm file .env để lấy thông tin database
ENV_FILE="$SITES_DIR/$SITE_NAME/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ $(date '+%Y-%m-%d %H:%M:%S') - Không tìm thấy .env trong $SITES_DIR/$SITE_NAME!" >> "$LOG_FILE"
    exit 1
fi

DB_NAME=$(grep "^MYSQL_DATABASE=" "$ENV_FILE" | cut -d '=' -f2)
DB_USER=$(grep "^MYSQL_USER=" "$ENV_FILE" | cut -d '=' -f2)
DB_PASS=$(grep "^MYSQL_PASSWORD=" "$ENV_FILE" | cut -d '=' -f2)

if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
    echo "❌ $(date '+%Y-%m-%d %H:%M:%S') - Lỗi: Không thể lấy thông tin database từ .env!" >> "$LOG_FILE"
    exit 1
fi

WEB_ROOT="$SITES_DIR/$SITE_NAME/wordpress"

echo "🔄 $(date '+%Y-%m-%d %H:%M:%S') - Đang backup database..." >> "$LOG_FILE"
backup_database "$SITE_NAME" "$DB_NAME" "$DB_USER" "$DB_PASS" >> "$LOG_FILE" 2>&1

echo "🔄 $(date '+%Y-%m-%d %H:%M:%S') - Đang backup mã nguồn..." >> "$LOG_FILE"
backup_files "$SITE_NAME" "$WEB_ROOT" >> "$LOG_FILE" 2>&1

echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - Hoàn thành backup $SITE_NAME!" >> "$LOG_FILE"
