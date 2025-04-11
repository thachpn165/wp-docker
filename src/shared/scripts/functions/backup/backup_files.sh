# Function: backup_file_logic
# Description:
#   Creates a backup of the WordPress files for a given domain. The backup is stored
#   as a compressed tarball in the domain's backup directory.
#
# Parameters:
#   $1 - The domain name for which the backup is to be created.
#
# Globals:
#   SITES_DIR - The base directory containing site-specific directories.
#   MSG_WEBSITE_BACKING_UP_FILES - Message to indicate the start of the backup process.
#   MSG_WEBSITE_BACKUP_FILE_CREATED - Message to indicate successful backup creation.
#   ERROR_BACKUP_FILE - Message to indicate an error during the backup process.
#
# Returns:
#   On success: Outputs the path to the created backup file.
#   On failure: Returns 1 and logs an error message.
#
# Dependencies:
#   - is_directory_exist: Function to check if a directory exists.
#   - print_and_debug: Function to log messages with different levels (info, success, error).
#   - run_cmd: Function to execute a command and optionally log its output.
#
# Usage:
#   backup_file_logic "example.com"
backup_file_logic() {
    local domain="$1"
    local web_root
    web_root="$SITES_DIR/${domain}/wordpress"  # Automatically determine web root
    local backup_dir
    backup_dir="$SITES_DIR/${domain}/backups"
    local backup_file
    backup_file="${backup_dir}/files-${domain}-$(date +%Y%m%d-%H%M%S).tar.gz"

    # Check if param exists
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        return 1
    fi
    is_directory_exist "$backup_dir"
    is_directory_exist "$SITES_DIR/$domain/logs"
    is_directory_exist "$web_root"

    print_and_debug info "$MSG_WEBSITE_BACKING_UP_FILES : ${domain}"
    run_cmd "tar -czf ${backup_file} -C ${web_root} ." true

    if [[ $? -eq 0 ]]; then
        print_and_debug success "$MSG_WEBSITE_BACKUP_FILE_CREATED : ${backup_file}"
        echo -n "$backup_file"  # Return only the path, no log
    else
        print_and_debug error "$ERROR_BACKUP_FILE"
        return 1
    fi
}
