# ============================================
# 📦 backup_file_logic – Backup WordPress source files
# ============================================
# Description:
#   - Creates a compressed `.tar.gz` archive of the `wordpress/` directory for the given domain.
#
# Parameters:
#   $1 - domain (required)
#
# Globals:
#   SITES_DIR
#   MSG_WEBSITE_BACKING_UP_FILES
#   MSG_WEBSITE_BACKUP_FILE_CREATED
#   ERROR_BACKUP_FILE
#
# Returns:
#   - Echoes the path to the backup file if successful
#   - Returns 1 and logs an error message on failure
# ============================================
backup_file_logic() {
    local domain="$1"

    # === Validate input ===
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        return 1
    fi

    local web_root="$SITES_DIR/${domain}/wordpress"
    local backup_dir="$SITES_DIR/${domain}/backups"
    local log_dir="$SITES_DIR/${domain}/logs"
    local backup_file="${backup_dir}/files-${domain}-$(date +%Y%m%d-%H%M%S).tar.gz"

    # === Ensure necessary directories exist ===
    is_directory_exist "$web_root"
    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

    # === Start backup process ===
    print_and_debug info "$MSG_WEBSITE_BACKING_UP_FILES: $domain"
    run_cmd "tar -czf \"$backup_file\" -C \"$web_root\" ." true

    # === Verify result ===
    if [[ $? -eq 0 ]]; then
        print_and_debug success "$MSG_WEBSITE_BACKUP_FILE_CREATED: $backup_file"
        echo -n "$backup_file"
    else
        print_and_debug error "$ERROR_BACKUP_FILE"
        return 1
    fi
}
