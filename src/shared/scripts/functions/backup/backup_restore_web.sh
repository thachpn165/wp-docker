backup_prompt_restore_web() {
    source "$CLI_DIR/backup_restore.sh"

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
    backup_cli_restore_web --domain="$domain" --code_backup_file="$code_backup_file" --db_backup_file="$db_backup_file"

}

backup_logic_restore_web() {
    local domain="$1"
    local code_backup_file="$2"
    local db_backup_file="$3"
    local site_dir="$SITES_DIR/$domain"

    # Ensure website directory exists
    if ! is_directory_exist "$site_dir"; then
        print_and_debug error "$MSG_NOT_FOUND: $site_dir"
        return 1
    fi

    # === Restore Source Code ===
    if [[ -n "$code_backup_file" ]]; then
        # Check if filename has relative path, convert to absolute path
        if [[ ! "$code_backup_file" =~ ^/ ]]; then
            code_backup_file="$site_dir/backups/$code_backup_file"
        fi

        # Call the restore files function
        backup_restore_files "$code_backup_file" "$site_dir"
    fi

    # === Restore Database ===
    if [[ -n "$db_backup_file" ]]; then

        # Check if filename has relative path, convert to absolute path
        if [[ ! "$db_backup_file" =~ ^/ ]]; then
            db_backup_file="$site_dir/backups/$db_backup_file"
        fi

        # Call the restore database function
        backup_restore_database "$db_backup_file" "$domain"
    fi

    #echo -e "${GREEN}${CHECKMARK} Website '$domain' restore completed.${NC}"
    print_and_debug success "$SUCCESS_BACKUP_RESTORED_DB: $domain"
}
