#!/bin/bash

ensure_directory_exists() {
    local dir_path="$1"
    if [[ ! -d "$dir_path" ]]; then
        echo "📂 Tạo thư mục: $dir_path"
        mkdir -p "$dir_path"
    fi
}


# Chức năng backup website
backup_website() {
    select_website || return

    read -p "Nhập tên database: " DB_NAME
    read -p "Nhập user database: " DB_USER
    read -s -p "Nhập mật khẩu database: " DB_PASS
    echo ""
    read -p "Nhập thư mục gốc website (VD: /var/www/${SITE_NAME}): " WEB_ROOT

    backup_database "$SITE_NAME" "$DB_NAME" "$DB_USER" "$DB_PASS"
    backup_files "$SITE_NAME" "$WEB_ROOT"
}

# Chức năng xóa backup cũ
cleanup_old_backups() {
    select_website || return

    read -p "Giữ lại backup trong bao nhiêu ngày? (VD: 7): " RETENTION_DAYS
    cleanup_backups "$SITE_NAME" "$RETENTION_DAYS"
}

# Chức năng xem danh sách backup
list_backup_files() {
    select_website || return

    echo "📂 Danh sách backup của $SITE_NAME:"
    ls -lh "$SITES_DIR/$SITE_NAME/backups/"
}