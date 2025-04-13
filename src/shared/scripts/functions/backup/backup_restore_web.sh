# =============================================
# 🧭 backup_prompt_restore_web – Interactive backup restore prompt
# ---------------------------------------------
# This function:
#   - Allows the user to select a website
#   - Prompts to restore source code (tar.gz) and/or database (sql)
#   - Lists available backup files for selection
#   - Passes the selected backup files to the CLI restore function
#
# i18n Variables:
#   PROMPT_CONFIRM_RESTORE_SOURCE, PROMPT_CONFIRM_RESTORE_DB, PROMPT_ENTER_BACKUP_FILE
#   ERROR_SITE_NOT_SELECTED, ERROR_BACKUP_FILE_NOT_FOUND
#   SUCCESS_BACKUP_FILE_FOUND, INFO_SKIP_SOURCE_RESTORE, INFO_SKIP_DB_RESTORE
#   INFO_LIST_BACKUP_SOURCE_FILES, INFO_LIST_BACKUP_DB_FILES, MSG_WEBSITE_SELECTED
# =============================================

backup_prompt_restore_web() {
    safe_source "$CLI_DIR/backup_restore.sh"

    select_website
    [[ -z "$domain" ]] && print_msg error "$ERROR_SITE_NOT_SELECTED" && exit 1
    print_msg info "$MSG_WEBSITE_SELECTED: $domain"

    # === Prompt: Restore source code ===
    confirm_code=$(get_input_or_test_value "$PROMPT_CONFIRM_RESTORE_SOURCE" "${TEST_CONFIRM_RESTORE_SOURCE:-y}" | tr '[:upper:]' '[:lower:]')
    if [[ "$confirm_code" == "y" ]]; then
        print_msg info "$INFO_LIST_BACKUP_SOURCE_FILES"
        find "$SITES_DIR/$domain/backups" -name "*.tar.gz" | while read -r file; do
            file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
            echo -e "$(basename "$file")\t$file_time"
        done | nl -s ". "

        code_backup_file=$(get_input_or_test_value "$PROMPT_ENTER_BACKUP_FILE" "${TEST_CODE_BACKUP_FILE:-backup.tar.gz}")
        [[ "$code_backup_file" != /* ]] && code_backup_file="$SITES_DIR/$domain/backups/$code_backup_file"

        [[ ! -f "$code_backup_file" ]] && print_msg error "$ERROR_BACKUP_FILE_NOT_FOUND: $code_backup_file" && exit 1
        print_msg success "$SUCCESS_BACKUP_FILE_FOUND: $code_backup_file"
    else
        print_msg info "$INFO_SKIP_SOURCE_RESTORE"
        code_backup_file=""
    fi

    # === Prompt: Restore database ===
    confirm_db=$(get_input_or_test_value "$PROMPT_CONFIRM_RESTORE_DB" "${TEST_CONFIRM_RESTORE_DB:-y}" | tr '[:upper:]' '[:lower:]')
    if [[ "$confirm_db" == "y" ]]; then
        print_msg info "$INFO_LIST_BACKUP_DB_FILES"
        find "$SITES_DIR/$domain/backups" -name "*.sql" | while read -r file; do
            file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
            echo -e "$(basename "$file")\t$file_time"
        done | nl -s ". "

        db_backup_file=$(get_input_or_test_value "$PROMPT_ENTER_BACKUP_FILE" "${TEST_DB_BACKUP_FILE:-backup.sql}")
        [[ "$db_backup_file" != /* ]] && db_backup_file="$SITES_DIR/$domain/backups/$db_backup_file"

        [[ ! -f "$db_backup_file" ]] && print_msg error "$ERROR_BACKUP_FILE_NOT_FOUND: $db_backup_file" && exit 1
        print_msg success "$SUCCESS_BACKUP_FILE_FOUND: $db_backup_file"
    else
        print_msg info "$INFO_SKIP_DB_RESTORE"
        db_backup_file=""
    fi

    # === Call restore CLI ===
    backup_cli_restore_web --domain="$domain" --code_backup_file="$code_backup_file" --db_backup_file="$db_backup_file"
}
# =============================================
# ♻️ backup_logic_restore_web – Restore WordPress website from backup files
# ---------------------------------------------
# This function:
#   - Validates the site directory
#   - Restores source code from .tar.gz if provided
#   - Restores database from .sql if provided
#
# Parameters:
#   $1 - domain
#   $2 - code_backup_file (optional)
#   $3 - db_backup_file (optional)
#
# i18n Variables:
#   MSG_NOT_FOUND, SUCCESS_BACKUP_RESTORED_DB
# =============================================

backup_logic_restore_web() {
    local domain="$1"
    local code_backup_file="$2"
    local db_backup_file="$3"
    local site_dir="$SITES_DIR/$domain"

    if ! is_directory_exist "$site_dir"; then
        print_and_debug error "$MSG_NOT_FOUND: $site_dir"
        return 1
    fi

    # === Restore source code ===
    if [[ -n "$code_backup_file" ]]; then
        [[ "$code_backup_file" != /* ]] && code_backup_file="$site_dir/backups/$code_backup_file"
        backup_restore_files "$code_backup_file" "$site_dir"
    fi

    # === Restore database ===
    if [[ -n "$db_backup_file" ]]; then
        [[ "$db_backup_file" != /* ]] && db_backup_file="$site_dir/backups/$db_backup_file"
        backup_restore_database "$db_backup_file" "$domain"
    fi

    print_and_debug success "$SUCCESS_BACKUP_RESTORED_DB: $domain"
}