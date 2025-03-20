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
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_files.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_database.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"


backup_runner() {
    local site_name="$1"
    local storage_option="$2"

    if [[ -z "$site_name" ]]; then
        echo -e "${RED}❌ Lỗi: Không tìm thấy tên website để backup!${NC}"
        exit 1
    fi

    local env_file="$SITES_DIR/$site_name/.env"
    local web_root="$SITES_DIR/$site_name/wordpress"
    local backup_dir="$(realpath "$SITES_DIR/$site_name/backups")"
    local log_dir="$(realpath "$SITES_DIR/$site_name/logs")"

    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

    if [[ ! -f "$env_file" ]]; then
        echo -e "${RED}❌ Không tìm thấy tập tin .env trong $SITES_DIR/$site_name!${NC}"
        exit 1
    fi

    # Lấy thông tin database từ .env
    DB_NAME=$(grep "^MYSQL_DATABASE=" "$env_file" | cut -d '=' -f2)
    DB_USER=$(grep "^MYSQL_USER=" "$env_file" | cut -d '=' -f2)
    DB_PASS=$(grep "^MYSQL_PASSWORD=" "$env_file" | cut -d '=' -f2)

    if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
        echo -e "${RED}❌ Lỗi: Không thể lấy thông tin database từ .env!${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Bắt đầu tiến trình backup tự động cho: $site_name${NC}"
    
    # Tiến hành backup
    db_backup_file=$(backup_database "$site_name" "$DB_NAME" "$DB_USER" "$DB_PASS" | tail -n 1)
    files_backup_file=$(backup_files "$site_name" "$web_root" | tail -n 1)

    # Kiểm tra nếu file backup đã tồn tại
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        echo -e "${RED}❌ Lỗi: Không thể tìm thấy tập tin backup!${NC}"
        exit 1
    fi

    if [[ "$storage_option" == "local" ]]; then
        echo -e "${GREEN}💾 Backup hoàn tất và lưu tại: $backup_dir${NC}"
    else
        echo -e "${GREEN}☁️  Đang lưu backup lên Storage: '$storage_option'${NC}"

        # Kiểm tra storage có tồn tại trong rclone.conf không
        if ! grep -q "^\[$storage_option\]" "$RCLONE_CONFIG_FILE"; then
            echo -e "${RED}❌ Lỗi: Storage '$storage_option' không tồn tại trong rclone.conf!${NC}"
            exit 1
        fi

        # Gọi upload backup
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$storage_option" "$db_backup_file" "$files_backup_file"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Backup và upload lên Storage hoàn tất!${NC}"
            
            # Xóa tập tin backup sau khi upload thành công
            echo -e "${YELLOW}🗑️ Đang xóa tập tin backup sau khi upload thành công...${NC}"
            rm -f "$db_backup_file" "$files_backup_file"

            # Kiểm tra nếu file đã bị xóa
            if [[ ! -f "$db_backup_file" && ! -f "$files_backup_file" ]]; then
                echo -e "${GREEN}✅ Tập tin backup đã được xóa khỏi thư mục backups.${NC}"
            else
                echo -e "${RED}❌ Lỗi: Không thể xóa tập tin backup!${NC}"
            fi
        else
            echo -e "${RED}❌ Lỗi khi upload backup lên Storage!${NC}"
        fi
    fi
}

# Thực thi nếu script được gọi từ cronjob
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_runner "$@"
fi
