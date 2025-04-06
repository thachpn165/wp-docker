backup_restore_web_logic() {
    local domain="$1"
    local code_backup_file="$2"
    local db_backup_file="$3"
    local test_mode="$4"
    local site_dir="$SITES_DIR/$domain"
    local db_container=$(fetch_env_variable "$SITES_DIR/$domain/.env" "CONTAINER_DB")

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
        backup_restore_database "$db_backup_file" "$db_container" "$domain"
    fi

    echo -e "${GREEN}${CHECKMARK} Website '$domain' restore completed.${NC}"
}