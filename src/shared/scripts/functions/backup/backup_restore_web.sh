#!/bin/bash
# ==================================================
# File: backup_restore_web.sh
# Description: Functions to restore WordPress websites from backup files, including source code 
#              and database restoration.
# Functions:
#   - backup_prompt_restore_web: Interactive prompt for restoring website backups.
#       Parameters: None.
#   - backup_logic_restore_web: Logic to restore a WordPress website from backup files.
#       Parameters:
#           $1 - domain: The domain name of the website.
#           $2 - code_backup_file (optional): Path to the source code backup file (.tar.gz).
#           $3 - db_backup_file (optional): Path to the database backup file (.sql).
# ==================================================

backup_prompt_restore_web() {
    safe_source "$CLI_DIR/backup_restore.sh"
    local domain

    if ! website_get_selected domain; then
        return 1
    fi
    print_msg info "$MSG_WEBSITE_SELECTED: $domain"

    # List source code backup files
    print_msg info "$INFO_LIST_BACKUP_SOURCE_FILES"
    find "$SITES_DIR/$domain/backups" -name "*.tar.gz" | while read -r file; do
        file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
        echo -e "$(basename "$file")\t$file_time"
    done | nl -s ". "

    code_backup_file=$(get_input_or_test_value "$PROMPT_ENTER_BACKUP_FILE" "${TEST_CODE_BACKUP_FILE:-backup.tar.gz}")
    [[ "$code_backup_file" != /* ]] && code_backup_file="$SITES_DIR/$domain/backups/$code_backup_file"

    if [[ ! -f "$code_backup_file" ]]; then
        print_msg error "$ERROR_BACKUP_FILE_NOT_FOUND: $code_backup_file"
        exit 1
    fi
    print_msg success "$SUCCESS_BACKUP_FILE_FOUND: $code_backup_file"

    # List database backup files
    print_msg info "$INFO_LIST_BACKUP_DB_FILES"
    find "$SITES_DIR/$domain/backups" -name "*.sql" | while read -r file; do
        file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
        echo -e "$(basename "$file")\t$file_time"
    done | nl -s ". "

    db_backup_file=$(get_input_or_test_value "$PROMPT_ENTER_BACKUP_FILE" "${TEST_DB_BACKUP_FILE:-backup.sql}")
    [[ "$db_backup_file" != /* ]] && db_backup_file="$SITES_DIR/$domain/backups/$db_backup_file"

    if [[ ! -f "$db_backup_file" ]]; then
        print_msg error "$ERROR_BACKUP_FILE_NOT_FOUND: $db_backup_file"
        exit 1
    fi
    print_msg success "$SUCCESS_BACKUP_FILE_FOUND: $db_backup_file"

    # Call CLI to perform restore
    backup_cli_restore_web --domain="$domain" --code_backup_file="$code_backup_file" --db_backup_file="$db_backup_file"
}

backup_logic_restore_web() {
    local domain="$1"
    local code_backup_file="$2"
    local db_backup_file="$3"
    local site_dir="$SITES_DIR/$domain"

    if ! _is_directory_exist "$site_dir"; then
        print_and_debug error "$MSG_NOT_FOUND: $site_dir"
        return 1
    fi

    # Restore source code
    if [[ -n "$code_backup_file" ]]; then
        [[ "$code_backup_file" != /* ]] && code_backup_file="$site_dir/backups/$code_backup_file"
        backup_restore_files "$code_backup_file" "$site_dir"
    fi

    # Restore database
    if [[ -n "$db_backup_file" ]]; then
        [[ "$db_backup_file" != /* ]] && db_backup_file="$site_dir/backups/$db_backup_file"
        backup_restore_database "$db_backup_file" "$domain"
    fi

    print_and_debug success "$SUCCESS_BACKUP_RESTORED_DB: $domain"
}