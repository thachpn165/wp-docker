safe_source "$CLI_DIR/database_actions.sh"

# =====================================
# database_prompt_import: Prompt user to import a database for a selected site
# Requires:
#   - select_website to choose domain
#   - get_input_or_test_value to ask for .sql file path
#   - Global variable TEST_BACKUP_FILE (optional)
# =====================================
database_prompt_import() {
    local domain 
    print_msg info "$PROMPT_DATABASE_IMPORT_WEBSITE"
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_SITE_NOT_SELECTED"
        exit 1
    fi
    _is_valid_domain "$domain" || return 1
    # Prompt user to input the SQL backup file path
    backup_file=$(get_input_or_test_value "$PROMPT_DATABASE_ENTER_SQLFILE" "${TEST_BACKUP_FILE:-backup.sql}")

    # Ensure the backup file path is provided
    if [[ -z "$backup_file" ]]; then
        print_msg error "$ERROR_SQL_FILE_NOT_FOUND"
        exit 1
    fi

    # Execute the CLI import command
    database_cli_import --domain="$domain" --backup_file="$backup_file"
}

# =====================================
# database_import_logic: Import a SQL database into the site’s container
# Parameters:
#   $1 - domain: The site domain name
#   $2 - backup_file: Path to the .sql file to restore
# Requires:
#   - json_get_site_value for DB info
#   - is_mariadb_running to check container status
#   - docker exec and cp to interact with container
# =====================================
database_import_logic() {
    local domain="$1"
    local backup_file="$2"

    # Check if the sites directory is set
    if [[ -z "$SITES_DIR" ]]; then
        print_msg error "$ERROR_CONFIG_SITES_DIR_NOT_SET"
        return 1
    fi

    # Validate the domain name
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_PARAM_SITE_NAME_REQUIRED"
        return 1
    fi
    _is_valid_domain "$domain" || return 1
    # Validate the SQL file existence
    if [[ ! -f "$backup_file" ]]; then
        print_msg error "$MSG_NOT_FOUND: $backup_file"
        return 1
    fi

    # Get DB container name from config
    local db_container
    db_container="$MYSQL_CONTAINER_NAME"

    debug_log "[DB IMPORT] Domain: $domain"
    debug_log "[DB IMPORT] Backup file: $backup_file"

    # Get DB credentials
    local db_name db_user db_password
    db_name="$(json_get_site_value "$domain" "db_name")"
    db_user="$(json_get_site_value "$domain" "db_user")"
    db_password="$(json_get_site_value "$domain" "db_pass")"
    debug_log "[DB IMPORT] db_name=$db_name, db_user=$db_user"

    # Ensure MariaDB is running
    if ! core_mysql_check_running; then
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    fi

    # Notify restoring process
    local formatted_msg_restoring_database
    formatted_msg_restoring_database="$(printf "$MSG_BACKUP_RESTORING_DB" "$backup_file" "$domain")"
    print_msg step "$formatted_msg_restoring_database"

    # Copy SQL file to container
    docker cp "$backup_file" "$db_container:/tmp/restore.sql"
    debug_log "[DB IMPORT] Copied SQL file to container: /tmp/restore.sql"

    # Drop and recreate the database
    local sql_cmd="DROP DATABASE IF EXISTS \`$db_name\`; CREATE DATABASE \`$db_name\`;"
    docker exec --env MYSQL_PWD="$db_password" "$db_container" \
        mysql -u "$db_user" -e "$sql_cmd"
    debug_log "[DB IMPORT] SQL Command: $sql_cmd"

    # Import SQL data into the database
    if ! docker exec --env MYSQL_PWD="$db_password" "$db_container" \
        sh -c "mysql -u $db_user $db_name < /tmp/restore.sql"; then
        print_msg error "$(printf "$ERROR_BACKUP_RESTORE_FAILED" "$db_name")"
        return 1
    fi

    # Clean up temporary file
    docker exec "$db_container" rm -f /tmp/restore.sql
    debug_log "[DB IMPORT] Removed temp SQL file"

    # Display success message
    print_msg success "$(printf "$SUCCESS_BACKUP_RESTORED_DB" "$db_name")"
}