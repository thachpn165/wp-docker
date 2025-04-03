backup_website_logic() {
    if [[ -z "$domain" ]]; then
        log_with_time "${RED}${CROSSMARK} Error: SITE_DOMAIN is not set!${NC}"
        return 1
    fi

    local domain="$1"  # Get site name from argument
    local storage="$2"  # Get storage option (local or cloud)
    local rclone_storage="$3"  # Get rclone storage from argument

    # Define backup and log directories
    local backup_dir="$(realpath "$SITES_DIR/$domain/backups")"
    local log_dir="$(realpath "$SITES_DIR/$domain/logs")"
    local log_file="$log_dir/wp-backup.log"

    # Ensure backup and logs directories exist
    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

    # Log start of backup process
    log_with_time "${GREEN}${CHECKMARK} Starting backup process for site: $domain${NC}"

    # Backup database using the existing database_export_logic
    log_with_time "🔄 Backing up database..."
    db_backup_file=$(bash "$CLI_DIR/database_export.sh" --domain="$domain" | tail -n 1)

    log_with_time "🔄 Backing up source code..."
    files_backup_file=$(bash "$CLI_DIR/backup_file.sh" --domain="$domain" | tail -n 1)

    # Check if backup files exist
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        log_with_time "${RED}${CROSSMARK} Error: Could not find backup files!${NC}"
        return 1
    fi

    log_with_time "${YELLOW}🔹 Backup completed: Database and files saved.${NC}"

    # Ensure valid storage option
    if [[ "$storage" != "local" && "$storage" != "cloud" ]]; then
        log_with_time "${RED}${CROSSMARK} Invalid storage choice! Please use 'local' or 'cloud'.${NC}"
        return 1
    fi

    if [[ "$storage" == "cloud" && -z "$rclone_storage" ]]; then
        log_with_time "${RED}${CROSSMARK} rclone storage is required for cloud backup!${NC}"
        return 1
    fi

    if [[ "$storage" == "cloud" ]]; then
        log_with_time "${BLUE}📂 Uploading backup to Storage: $rclone_storage${NC}"

        # Check if storage exists in rclone.conf
        if ! grep -q "^\[$rclone_storage\]" "$RCLONE_CONFIG_FILE"; then
            log_with_time "${RED}${CROSSMARK} Error: Storage '$rclone_storage' does not exist in rclone.conf!${NC}"
            return 1
        fi

        # Call upload backup to the specified rclone storage
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$rclone_storage" "$db_backup_file" "$files_backup_file"

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
    elif [[ "$storage" == "local" ]]; then
        log_with_time "${GREEN}${SAVE} Backup completed and saved to: $backup_dir${NC}"
    fi
}