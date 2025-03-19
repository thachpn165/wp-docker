#!/bin/bash

# Import các hàm cần thiết từ backup-manager
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_files.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_database.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"

# Chức năng backup website
backup_website() {
    select_website || return

    local env_file="$SITES_DIR/$SITE_NAME/.env"
    local web_root="$SITES_DIR/$SITE_NAME/wordpress"

    if [[ ! -f "$env_file" ]]; then
        echo -e "${RED}❌ Không tìm thấy tập tin .env trong $SITES_DIR/$SITE_NAME!${NC}"
        return 1
    fi

    # Lấy thông tin database từ .env
    DB_NAME=$(grep "^MYSQL_DATABASE=" "$env_file" | cut -d '=' -f2)
    DB_USER=$(grep "^MYSQL_USER=" "$env_file" | cut -d '=' -f2)
    DB_PASS=$(grep "^MYSQL_PASSWORD=" "$env_file" | cut -d '=' -f2)

    if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
        echo -e "${RED}❌ Lỗi: Không thể lấy thông tin database từ .env!${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Đang sao lưu website: $SITE_NAME${NC}"
    echo -e "📂 Mã nguồn: $web_root"
    echo -e "🗄️ Database: $DB_NAME (User: $DB_USER)"

    backup_database "$SITE_NAME" "$DB_NAME" "$DB_USER" "$DB_PASS"
    backup_files "$SITE_NAME" "$web_root"
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

    local backup_dir="$SITES_DIR/$SITE_NAME/backups"

    if ! is_directory_exist "$backup_dir"; then
        echo -e "${RED}❌ Không tìm thấy thư mục backup trong $backup_dir${NC}"
        return 1
    fi

    echo -e "${BLUE}📂 Danh sách backup của $SITE_NAME:${NC}"

    # Xác định hệ điều hành (macOS hoặc Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        FIND_CMD="ls -lt $backup_dir | awk '{print \$6, \$7, \$8, \$9}'"
    else
        FIND_CMD="find $backup_dir -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r"
    fi

    # Hiển thị backup database
    echo -e "${GREEN}🗄️ Backup Database:${NC}"
    eval "$FIND_CMD" | grep "db-.*\.sql" | awk '{print "  📄 " $1, $2, "-", $NF}'

    # Hiển thị backup mã nguồn
    echo -e "${YELLOW}📂 Backup Mã nguồn:${NC}"
    eval "$FIND_CMD" | grep "files-.*\.tar.gz" | awk '{print "  📦 " $1, $2, "-", $NF}'
}



