#!/bin/bash

# Import các hàm cần thiết từ backup-manager
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_files.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_database.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"

backup_website() {
    select_website || return

    local env_file="$SITES_DIR/$SITE_NAME/.env"
    local web_root="$SITES_DIR/$SITE_NAME/wordpress"
    local backup_dir="$(realpath "$SITES_DIR/$SITE_NAME/backups")"
    local log_dir="$(realpath "$SITES_DIR/$SITE_NAME/logs")"
    local db_backup_file=""
    local files_backup_file=""
    local storage_choice=""
    local selected_storage=""

    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

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

    echo -e "${GREEN}✅ Đang chuẩn bị sao lưu website: $SITE_NAME${NC}"
    echo -e "📂 Mã nguồn: $web_root"
    echo -e "🗄️ Database: $DB_NAME (User: $DB_USER)"

    # Hỏi người dùng nơi lưu backup trước khi backup
    echo -e "${BLUE}📂 Chọn nơi lưu backup:${NC}"
    echo -e "  ${GREEN}[1]${NC} 💾 Lưu vào máy chủ (local)"
    echo -e "  ${GREEN}[2]${NC} ☁️  Lưu vào Storage đã thiết lập"
    read -p "🔹 Chọn một tùy chọn (1-2): " storage_choice

    if [[ "$storage_choice" == "2" ]]; then
        echo -e "${BLUE}📂 Đang lấy danh sách Storage từ rclone.conf...${NC}"

        # Gọi `rclone_storage_list()` để lấy danh sách Storage
        local storages=()
        while IFS= read -r line; do
            storages+=("$line")
        done < <(rclone_storage_list)

        if [[ ${#storages[@]} -eq 0 ]]; then
            echo -e "${RED}❌ Không có Storage nào được thiết lập trong rclone.conf!${NC}"
            return 1
        fi

        # Hiển thị danh sách Storage rõ ràng
        echo -e "${BLUE}📂 Danh sách Storage khả dụng:${NC}"
        for storage in "${storages[@]}"; do
            echo -e "  ${GREEN}➜${NC} ${CYAN}$storage${NC}"
        done

        echo -e "${YELLOW}💡 Hãy nhập chính xác tên Storage từ danh sách trên.${NC}"
        while true; do
            read -p "🔹 Nhập tên Storage để sử dụng: " selected_storage
            selected_storage=$(echo "$selected_storage" | xargs)  # Loại bỏ khoảng trắng thừa

            # Kiểm tra nếu storage tồn tại trong danh sách
            if [[ " ${storages[*]} " =~ " ${selected_storage} " ]]; then
                echo -e "${GREEN}☁️  Đã chọn Storage: '$selected_storage'${NC}"
                break
            else
                echo -e "${RED}❌ Storage không hợp lệ! Vui lòng nhập đúng tên Storage.${NC}"
            fi
        done
    fi

    # Bắt đầu tiến trình backup
    echo -e "${YELLOW}🔹 Đang sao lưu database và mã nguồn...${NC}"
    db_backup_file=$(backup_database "$SITE_NAME" "$DB_NAME" "$DB_USER" "$DB_PASS" | tail -n 1)
    files_backup_file=$(backup_files "$SITE_NAME" "$web_root" | tail -n 1)

    # Kiểm tra nếu file backup đã tồn tại
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        echo -e "${RED}❌ Lỗi: Không thể tìm thấy tập tin backup!${NC}"
        echo -e "${RED}🛑 Đường dẫn kiểm tra:${NC}"
        echo -e "📂 Database: $db_backup_file"
        echo -e "📂 Files: $files_backup_file"
        return 1
    fi

    if [[ "$storage_choice" == "1" ]]; then
        echo -e "${GREEN}💾 Backup hoàn tất và lưu tại: $backup_dir${NC}"
    elif [[ "$storage_choice" == "2" ]]; then
        echo -e "${GREEN}☁️  Đang lưu backup lên Storage: '$selected_storage'${NC}"

        # Kiểm tra storage có tồn tại trong rclone.conf không
        if ! grep -q "^\[$selected_storage\]" "$RCLONE_CONFIG_FILE"; then
            echo -e "${RED}❌ Lỗi: Storage '$selected_storage' không tồn tại trong rclone.conf!${NC}"
            return 1
        fi

        # Gọi upload backup
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$selected_storage" "$db_backup_file" "$files_backup_file"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Backup và upload lên Storage hoàn tất!${NC}"
        else
            echo -e "${RED}❌ Lỗi khi upload backup lên Storage!${NC}"
        fi
    fi
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



