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
# backup_manage: Quản lý backup, có thể liệt kê hoặc xóa các backup cũ dựa trên tham số
backup_manage() {
    local site_name="$1"
    local backup_dir="$SITES_DIR/$site_name/backups"
    local action="$2"
    local max_age_days="${3:-7}" 

    # Check if the backup directory exists
    if [[ ! -d "$backup_dir" ]]; then
        echo "${CROSSMARK} Directory $backup_dir not found!"
        return 1
    fi

    case "$action" in
        "list")
            # List backup files
            echo "Listing backups for $site_name in $backup_dir:"

            # Determine operating system (macOS or Linux)
            if [[ "$(uname)" == "Darwin" ]]; then
                FIND_CMD="ls -lt $backup_dir | awk '{print \$6, \$7, \$8, \$9}'"
            else
                FIND_CMD="find $backup_dir -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r"
            fi

            # List FILE BACKUP (.tar.gz files)
            echo -e "${YELLOW}📂 FILE BACKUP (tar.gz files):${NC}"
            eval $FIND_CMD | grep ".tar.gz"
            if [[ $? -eq 0 ]]; then
                echo "${CHECKMARK} File backup listing completed."
            else
                echo "${CROSSMARK} Error listing file backups."
            fi
            
            # List DATABASE BACKUP (.sql files)
            echo -e "${YELLOW}📂 DATABASE BACKUP (sql files):${NC}"
            eval $FIND_CMD | grep ".sql"
            if [[ $? -eq 0 ]]; then
                echo "${CHECKMARK} Database backup listing completed."
            else
                echo "${CROSSMARK} Error listing database backups."
            fi
            ;;
        "clean")
            # Remove old backup files
            echo "Cleaning old backups older than $max_age_days days in $backup_dir"
            find "$backup_dir" -type f -name "*.tar.gz" -mtime +$max_age_days -exec rm -f {} \;
            if [[ $? -eq 0 ]]; then
                echo "${CHECKMARK} Old backups older than $max_age_days days have been removed from $backup_dir."
            else
                echo "${CROSSMARK} Error removing old backups."
                return 1
            fi
            ;;
        *)
            echo "${CROSSMARK} Invalid action: $action. Use 'list' or 'clean'."
            return 1
            ;;
    esac
}