backup_restore_web_logic() {
    local domain="$1"
    local code_backup_file="$2"
    local db_backup_file="$3"
    local test_mode="$4"
    local site_dir="$SITES_DIR/$domain"
    local db_container="${domain}-mariadb"

    # Ensure website directory exists
    if ! is_directory_exist "$site_dir"; then
        echo -e "${RED}${CROSSMARK} Website directory does not exist: $site_dir${NC}"
        return 1
    fi

    # === Restore Source Code ===
    if [[ -n "$code_backup_file" ]]; then
        echo -e "📦 Restoring source code from $code_backup_file..."

        # Check if filename has relative path, convert to absolute path
        if [[ ! "$code_backup_file" =~ ^/ ]]; then
            code_backup_file="$site_dir/backups/$code_backup_file"
        fi

        # Check if the source code backup file exists
        if [[ ! -f "$code_backup_file" ]]; then
            echo "${CROSSMARK} Source code backup file does not exist: $code_backup_file"
            return 1
        else
            echo "${CHECKMARK} Found source code backup file: $code_backup_file"
        fi

        # Call the restore files function
        backup_restore_files "$code_backup_file" "$site_dir"
        exit_if_error "$?" "Source code restore failed!"
    fi

    # === Restore Database ===
    if [[ -n "$db_backup_file" ]]; then
        echo -e "🛢 Restoring database from $db_backup_file..."

        # Check if filename has relative path, convert to absolute path
        if [[ ! "$db_backup_file" =~ ^/ ]]; then
            db_backup_file="$site_dir/backups/$db_backup_file"
        fi

        # Check if the database backup file exists
        if [[ ! -f "$db_backup_file" ]]; then
            echo "${CROSSMARK} Database backup file does not exist: $db_backup_file"
            return 1
        else
            echo "${CHECKMARK} Found database backup file: $db_backup_file"
        fi

        # Call the restore database function
        backup_restore_database "$db_backup_file" "$db_container" "$domain"
        exit_if_error "$?" "Database restore failed!"
    fi

    echo -e "${GREEN}${CHECKMARK} Website '$domain' restore completed.${NC}"
}