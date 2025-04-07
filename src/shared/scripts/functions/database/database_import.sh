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
    db_container=$(fetch_env_variable "$SITES_DIR/$domain/.env" "CONTAINER_DB")
    if [[ -z "$db_container" ]]; then
        print_msg error "$(printf "$ERROR_ENV_NOT_FOUND" "$SITES_DIR/$domain/.env")"
        return 1
    fi

    debug_log "[DB IMPORT] Domain: $domain"
    debug_log "[DB IMPORT] Backup file: $backup_file"

    local db_info
    db_info=$(db_fetch_env "$domain")
    if [[ $? -ne 0 ]]; then
        print_msg error "$(printf "$ERROR_DB_FETCH_CREDENTIALS" "$domain")"
        return 1
    fi

    local db_name db_user db_password
    IFS=' ' read -r db_name db_user db_password <<< "$db_info"
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

    docker exec --env MYSQL_PWD="$db_password" "$db_container" \
        mysql -u "$db_user" -e "DROP DATABASE IF EXISTS \\`$db_name\\`; CREATE DATABASE \\`$db_name\\`;"

    if ! docker exec --env MYSQL_PWD="$db_password" "$db_container" \
        sh -c "mysql -u $db_user $db_name < /tmp/restore.sql"; then
        print_msg error "$(printf "$ERROR_BACKUP_RESTORE_FAILED" "$db_name")"
        return 1
    fi

    docker exec "$db_container" rm -f /tmp/restore.sql
    debug_log "[DB IMPORT] Removed temp SQL file"

    print_msg success "$(printf "$SUCCESS_BACKUP_RESTORED_DB" "$db_name")"
}
