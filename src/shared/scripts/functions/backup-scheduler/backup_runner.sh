#!/bin/bash

if [[ -z "$PROJECT_DIR" ]]; then
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
PROJECT_DIR="$SCRIPT_PATH"

break
fi
SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
fi

  

# === ${CHECKMARK} Load config.sh từ PROJECT_DIR ===

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
echo "${CROSSMARK} Không tìm thấy config.sh tại: $CONFIG_FILE" >&2
exit 1
fi
source "$CONFIG_FILE"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_files.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_database.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"

backup_runner() {
    local site_name="$1"
    local storage_option="$2"

    if [[ -z "$site_name" ]]; then
        log_with_time "${RED}${CROSSMARK} Error: No website name found for backup!${NC}"
        exit 1
    fi

    # If storage_option is empty, default to local
    if [[ -z "$storage_option" ]]; then
        storage_option="local"
    fi

    # Ensure backup and logs directories exist
    is_directory_exist "$SITES_DIR/$site_name/backups"
    is_directory_exist "$SITES_DIR/$site_name/logs"

    local env_file="$SITES_DIR/$site_name/.env"
    local web_root="$SITES_DIR/$site_name/wordpress"
    local backup_dir="$SITES_DIR/$site_name/backups"
    local log_dir="$(realpath "$SITES_DIR/$site_name/logs")"
    local log_file="$log_dir/wp-backup.log"

    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

    if [[ ! -f "$env_file" ]]; then
        log_with_time "${RED}${CROSSMARK} .env file not found in $SITES_DIR/$site_name!${NC}"
        exit 1
    fi

    # Get database information from .env
    DB_NAME=$(grep "^MYSQL_DATABASE=" "$env_file" | cut -d '=' -f2)
    DB_USER=$(grep "^MYSQL_USER=" "$env_file" | cut -d '=' -f2)
    DB_PASS=$(grep "^MYSQL_PASSWORD=" "$env_file" | cut -d '=' -f2)

    if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
        log_with_time "${RED}${CROSSMARK} Error: Could not get database information from .env!${NC}"
        exit 1
    fi

    log_with_time "${GREEN}${CHECKMARK} Starting automatic backup process for: $site_name${NC}"
    
    # Perform backup
    log_with_time "🔄 Backing up database..."
    db_backup_file=$(backup_database "$site_name" "$DB_NAME" "$DB_USER" "$DB_PASS" | tail -n 1)
    log_with_time "🔄 Backing up source code..."
    files_backup_file=$(backup_files "$site_name" "$web_root" | tail -n 1)

    # Check if backup files exist
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        log_with_time "${RED}${CROSSMARK} Error: Could not find backup files!${NC}"
        exit 1
    fi

    if [[ "$storage_option" == "local" ]]; then
        log_with_time "${GREEN}${SAVE} Backup completed and saved to: $backup_dir${NC}"
    else
        log_with_time "${GREEN}☁️  Saving backup to Storage: '$storage_option'${NC}"

        # Check if storage exists in rclone.conf
        if ! grep -q "^\[$storage_option\]" "$RCLONE_CONFIG_FILE"; then
            log_with_time "${RED}${CROSSMARK} Error: Storage '$storage_option' does not exist in rclone.conf!${NC}"
            exit 1
        fi

        # Call upload backup
        log_with_time "📤 Starting backup upload to Storage..."
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$storage_option" "$db_backup_file" "$files_backup_file" > /dev/null 2>>"$log_file"

        if [[ $? -eq 0 ]]; then
            log_with_time "${GREEN}${CHECKMARK} Backup and upload to Storage completed!${NC}"
            
            # Delete backup files after successful upload
            log_with_time "🗑️ Deleting backup files after successful upload..."
            rm -f "$db_backup_file" "$files_backup_file"

            # Check if files were deleted
            if [[ ! -f "$db_backup_file" && ! -f "$files_backup_file" ]]; then
                log_with_time "${GREEN}${CHECKMARK} Backup files have been deleted from backups directory.${NC}"
            else
                log_with_time "${RED}${CROSSMARK} Error: Could not delete backup files!${NC}"
            fi
        else
            log_with_time "${RED}${CROSSMARK} Error uploading backup to Storage!${NC}"
        fi
    fi

    log_with_time "${GREEN}${CHECKMARK} Completed automatic backup for: $site_name${NC}"
}

# Execute if script is called from cronjob
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_runner "$@"
fi
