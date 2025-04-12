safe_source "$CLI_DIR/database_actions.sh"
database_prompt_import() {
    echo "🔧 Choose the website for database import:"
    select_website || exit 1

    # Ensure SITE_DOMAIN is selected
    if [[ -z "$domain" ]]; then
        echo "${CROSSMARK} Site name is not set. Exiting..."
        exit 1
    fi

    # Ask for the .sql file path
    read -rp "Enter .sql file path: " backup_file

    # Ensure the file path is provided
    if [[ -z "$backup_file" ]]; then
        echo "${CROSSMARK} No file path provided. Exiting..."
        exit 1
    fi

    echo "💾 Importing database for site: $domain from backup file: $backup_file"

    # Call cli/database_import.sh with the selected site_name, db_user, db_password, db_name, and backup_file
    database_cli_import --domain="$domain" --backup_file="$backup_file"
}

database_import_logic() {
    local domain="$1"
    local backup_file="$2"

    if [[ -z "$SITES_DIR" ]]; then
        print_msg error "$ERROR_CONFIG_SITES_DIR_NOT_SET"
        return 1
    fi

    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_PARAM_SITE_NAME_REQUIRED"
        return 1
    fi

    if [[ ! -f "$backup_file" ]]; then
        print_msg error "$MSG_NOT_FOUND: $backup_file"
        return 1
    fi

    local db_container
    db_container=$(json_get_site_value "$domain" "CONTAINER_DB")

    debug_log "[DB IMPORT] Domain: $domain"
    debug_log "[DB IMPORT] Backup file: $backup_file"

    local db_name db_user db_password
    db_name="$(json_get_site_value "$domain" "MYSQL_DATABASE")"
    db_user="$(json_get_site_value "$domain" "MYSQL_USER")"
    db_password="$(json_get_site_value "$domain" "MYSQL_PASSWORD")"
    debug_log "[DB IMPORT] db_name=$db_name, db_user=$db_user"

    if ! is_mariadb_running "$domain"; then
        print_msg error "$(printf "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING" "$db_container")"
        return 1
    fi

    local formatted_msg_restoring_database
    formatted_msg_restoring_database="$(printf "$MSG_BACKUP_RESTORING_DB" "$backup_file" "$domain")"
    print_msg step "$formatted_msg_restoring_database"

    docker cp "$backup_file" "$db_container:/tmp/restore.sql"
    debug_log "[DB IMPORT] Copied SQL file to container: /tmp/restore.sql"

    local sql_cmd="DROP DATABASE IF EXISTS \`$db_name\`; CREATE DATABASE \`$db_name\`;"
    docker exec --env MYSQL_PWD="$db_password" "$db_container" \
        mysql -u "$db_user" -e "$sql_cmd"
    debug_log "[DB IMPORT] SQL Command: $sql_cmd"

    if ! docker exec --env MYSQL_PWD="$db_password" "$db_container" \
        sh -c "mysql -u $db_user $db_name < /tmp/restore.sql"; then
        print_msg error "$(printf "$ERROR_BACKUP_RESTORE_FAILED" "$db_name")"
        return 1
    fi

    docker exec "$db_container" rm -f /tmp/restore.sql
    debug_log "[DB IMPORT] Removed temp SQL file"

    print_msg success "$(printf "$SUCCESS_BACKUP_RESTORED_DB" "$db_name")"
}
