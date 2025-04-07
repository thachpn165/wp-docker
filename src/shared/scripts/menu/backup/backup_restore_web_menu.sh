#!/bin/bash

# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for website management
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Select website ===
select_website

# Ensure site is selected
if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_SITE_NOT_SELECTED"
    exit 1
fi

# === Ask for restoring source code ===
confirm_code=$(get_input_or_test_value "$PROMPT_CONFIRM_RESTORE_SOURCE" "${TEST_CONFIRM_RESTORE_SOURCE:-y}")
confirm_code=$(echo "$confirm_code" | tr '[:upper:]' '[:lower:]')

if [[ "$confirm_code" == "y" ]]; then
    print_msg info "$INFO_LIST_BACKUP_SOURCE_FILES"
    find "$SITES_DIR/$domain/backups" -type f -name "*.tar.gz" | while read -r file; do
        file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
        file_name=$(basename "$file")
        echo -e "$file_name\t$file_time"
    done | nl -s ". "

    code_backup_file=$(get_input_or_test_value "$PROMPT_ENTER_BACKUP_FILE" "${TEST_CODE_BACKUP_FILE:-backup.tar.gz}")
    if [[ ! "$code_backup_file" =~ ^/ ]]; then
        code_backup_file="$SITES_DIR/$domain/backups/$code_backup_file"
    fi

    if [[ ! -f "$code_backup_file" ]]; then
        print_msg error "$ERROR_BACKUP_FILE_NOT_FOUND: $code_backup_file"
        exit 1
    else
        print_msg success "$SUCCESS_BACKUP_FILE_FOUND: $code_backup_file"
    fi
else
    code_backup_file=""
    print_msg info "$INFO_SKIP_SOURCE_RESTORE"
fi

# === Ask for restoring database ===
confirm_db=$(get_input_or_test_value "$PROMPT_CONFIRM_RESTORE_DB" "${TEST_CONFIRM_RESTORE_DB:-y}")
confirm_db=$(echo "$confirm_db" | tr '[:upper:]' '[:lower:]')

if [[ "$confirm_db" == "y" ]]; then
    print_msg info "$INFO_LIST_BACKUP_DB_FILES"
    find "$SITES_DIR/$domain/backups" -type f -name "*.sql" | while read -r file; do
        file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
        file_name=$(basename "$file")
        echo -e "$file_name\t$file_time"
    done | nl -s ". "

    db_backup_file=$(get_input_or_test_value "$PROMPT_ENTER_BACKUP_FILE" "${TEST_DB_BACKUP_FILE:-backup.sql}")
    if [[ ! "$db_backup_file" =~ ^/ ]]; then
        db_backup_file="$SITES_DIR/$domain/backups/$db_backup_file"
    fi

    if [[ ! -f "$db_backup_file" ]]; then
        print_msg error "$ERROR_BACKUP_FILE_NOT_FOUND: $db_backup_file"
        exit 1
    else
        print_msg success "$SUCCESS_BACKUP_FILE_FOUND: $db_backup_file"
    fi

    #mysql_root_password=$(fetch_env_variable "$SITES_DIR/$domain/.env" "MYSQL_ROOT_PASSWORD")
    #if [[ -z "$mysql_root_password" ]]; then
    #    print_msg error "$ERROR_ENV_NOT_FOUND: MYSQL_ROOT_PASSWORD"
    #    exit 1
    #fi
else
    db_backup_file=""
    print_msg info "$INFO_SKIP_DB_RESTORE"
fi

# === Call the restore logic via CLI ===
bash "$CLI_DIR/backup_restore_web.sh" --domain="$domain" --code_backup_file="$code_backup_file" --db_backup_file="$db_backup_file"
