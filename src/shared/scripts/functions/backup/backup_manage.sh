# -----------------------------------------------------------------------------
# Function: backup_manage
# Description: Manages backups for a specified site. It can list existing backups
#              or clean up old backups based on the provided parameters.
#
# Parameters:
#   1. site_name (string)   - The name of the site whose backups are to be managed.
#   2. action (string)      - The action to perform: "list" to list backups or 
#                             "clean" to remove old backups.
#   3. max_age_days (int)   - (Optional) The maximum age of backups to retain 
#                             when cleaning. Defaults to 7 days.
#
# Behavior:
#   - If the action is "list", the function lists all backup files (.tar.gz and .sql)
#     in the backup directory for the specified site.
#   - If the action is "clean", the function removes backup files older than the 
#     specified number of days (default is 7 days).
#
# Notes:
#   - The function checks if the backup directory exists before proceeding.
#   - For "list" action, it determines the operating system (macOS or Linux) to 
#     use the appropriate command for listing files.
#   - For "clean" action, it uses the `find` command to delete old backup files.
#
# Returns:
#   - 0 on success.
#   - 1 on failure (e.g., invalid action, missing directory, or errors during execution).
#
# Example Usage:
#   backup_manage "example_site" "list"
#   backup_manage "example_site" "clean" 30
# -----------------------------------------------------------------------------

backup_manage() {
    local domain="$1"
    local backup_dir="$SITES_DIR/$domain/backups"
    local action="$2"
    local max_age_days="${3:-7}" 
    local formatted_msg_cleaning_old_backups
    formatted_msg_cleaning_old_backups=$(printf "$STEP_CLEANING_OLD_BACKUPS" "$max_age_days" "$backup_dir")

    # Check if the backup directory exists
    if [[ ! -d "$backup_dir" ]]; then
        print_and_debug error "$MSG_NOT_FOUND $backup_dir"
        mkdir -p "$backup_dir"
        debug_log "Backup directory $backup_dir created because it did not exist."
    fi

    case "$action" in
        "list")
            print_msg step "$MSG_BACKUP_LISTING: $domain"

            if [[ "$(uname)" == "Darwin" ]]; then
                print_msg label "$LABEL_BACKUP_FILE_LIST"
                ls -lt "$backup_dir" | awk '{print $6, $7, $8, $9}' | grep ".tar.gz"

                print_msg label "$LABEL_BACKUP_DB_LIST"
                ls -lt "$backup_dir" | awk '{print $6, $7, $8, $9}' | grep ".sql"
            else
                print_msg label "$LABEL_BACKUP_FILE_LIST"
                find "$backup_dir" -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | grep ".tar.gz"

                print_msg label "$LABEL_BACKUP_DB_LIST"
                find "$backup_dir" -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | grep ".sql"
            fi
            return 0
            ;;
        "clean")
            print_msg step "$formatted_msg_cleaning_old_backups"
            if [[ "$DEBUG_MODE" == true ]]; then
                local old_files_count
                old_files_count=$(find "$backup_dir" -type f \( -name "*.tar.gz" -o -name "*.sql" \) -mtime +$max_age_days | wc -l)
                debug_log "Found $old_files_count old backup files to delete (older than $max_age_days days)"
            fi
            find "$backup_dir" -type f -name "*.tar.gz" -mtime +$max_age_days -exec rm -f {} \;
            print_and_debug success "$SUCCESS_BACKUP_CLEAN"
            return 0
            ;;
        *)
            print_and_debug error "$ERROR_BACKUP_INVALID_ACTION"
            debug_log "Invalid action: $action"
            return 1
            ;;
    esac
}