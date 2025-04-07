backup_website_logic() {
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_SITE_DOMAIN_NOT_SET"
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
    print_msg step "$STEP_BACKUP_START: $domain"
    debug_log "[backup_website_logic] Backup dir: $backup_dir"
    debug_log "[backup_website_logic] Log file: $log_file"

    # Backup database using the existing database_export_logic
    print_msg info "$MSG_WEBSITE_BACKING_UP_DB"
    db_backup_file=$(bash "$CLI_DIR/database_export.sh" --domain="$domain" | tail -n 1)
    debug_log "[backup_website_logic] DB backup file: $db_backup_file"

    print_msg info "$MSG_WEBSITE_BACKING_UP_FILES"
    files_backup_file=$(bash "$CLI_DIR/backup_file.sh" --domain="$domain" | tail -n 1)
    debug_log "[backup_website_logic] Files backup file: $files_backup_file"

    # Check if backup files exist
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        print_and_debug error "$ERROR_BACKUP_FILE_NOT_FOUND"
        return 1
    fi

    print_msg success "$INFO_BACKUP_COMPLETED : $domain"

    # Ensure valid storage option
    if [[ "$storage" != "local" && "$storage" != "cloud" ]]; then
        print_and_debug error "$ERROR_INVALID_STORAGE_CHOICE"
        return 1
    fi

    if [[ "$storage" == "cloud" && -z "$rclone_storage" ]]; then
        print_and_debug error "$ERROR_RCLONE_STORAGE_REQUIRED"
        return 1
    fi

    if [[ "$storage" == "cloud" ]]; then
        formatted_msg="$(printf "$INFO_RCLONE_UPLOAD_START" "$rclone_storage")"
        print_msg info "$formatted_msg"

        # Check if storage exists in rclone.conf
        if ! grep -q "^\[$rclone_storage\]" "$RCLONE_CONFIG_FILE"; then
            print_and_debug error "$ERROR_STORAGE_NOT_EXIST"
            return 1
        fi

        # Call upload backup to the specified rclone storage
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$rclone_storage" "$db_backup_file" "$files_backup_file"
 
        if [[ $? -eq 0 ]]; then
            print_msg step "$MSG_BACKUP_UPLOAD_DONE : $rclone_storage"
            debug_log "[backup_website_logic] Backup files uploaded to $rclone_storage"

            # Delete backup files after successful upload
            print_msg step "$MSG_BACKUP_DELETE_LOCAL"
            rm -f "$db_backup_file" "$files_backup_file"

            # Check if files were deleted
            if [[ ! -f "$db_backup_file" && ! -f "$files_backup_file" ]]; then
                print_msg success "$SUCCESS_BACKUP_FILES_DELETED"
            else
                print_and_debug error "$ERROR_BACKUP_DELETE_FAILED"
            fi
        else
            print_and_debug error "$ERROR_BACKUP_UPLOAD_FAILED"
        fi
    elif [[ "$storage" == "local" ]]; then
        formatted_msg="$(printf "$SUCCESS_BACKUP_LOCAL_SAVED" "$backup_dir")"
        print_msg success "$formatted_msg"
    fi
}