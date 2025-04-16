# shellcheck disable=SC1091
safe_source "$CLI_DIR/database_actions.sh"

# =====================================
# database_prompt_export: Prompt user to select a site and run database export
# Requires: select_website function, global variable $save_location
# =====================================
database_prompt_export() {
    # Prompt user to select a website
    echo "🔧 Choose the website for backup:"
    select_website || exit 1

    # Validate domain selection
    if [[ -z "$domain" ]]; then
        echo "${CROSSMARK} Site name is not set. Exiting..."
        exit 1
    fi

    echo "💾 Backup will be saved to: $save_location"

    # Call CLI export command
    database_cli_export --domain="$domain" --save_location="$save_location"
}

# =====================================
# database_export_logic: Export database to a given location
# Parameters:
#   $1 - domain: The site domain name
#   $2 - save_location: Destination path for the backup file
# Requires:
#   - json_get_site_value to extract DB info
#   - is_mariadb_running to check DB container
#   - print_msg for i18n logging
# =====================================
database_export_logic() {
    local domain="$1"
    local save_location="$2"

    # Check if the sites directory is set
    if [[ -z "$SITES_DIR" ]]; then
        print_msg error "$ERROR_CONFIG_SITES_DIR_NOT_SET"
        return 1
    fi

    # Validate required parameter: domain/mysqldump

    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_PARAM_SITE_NAME_REQUIRED"
        return 1
    fi

    # Ensure backup directory exists
    local backup_dir
    backup_dir="$(dirname "$save_location")"
    if [[ ! -d "$backup_dir" ]]; then
        print_msg warning "$(printf "$WARNING_BACKUP_DIR_NOT_EXIST_CREATE" "$backup_dir")"
        mkdir -p "$backup_dir" || {
            print_msg error "$ERROR_BACKUP_CREATE_DIR_FAILED"
            return 1
        }
    fi

    # Retrieve database credentials from JSON config
    local db_name db_user db_password
    db_name="$(json_get_site_value "$domain" "db_name")"
    db_user="$(json_get_site_value "$domain" "db_user")"
    db_password="$(json_get_site_value "$domain" "db_pass")"
    debug_log "[DB EXPORT] db_name=$db_name, db_user=$db_user"
    debug_log "[DB EXPORT] save_location=$save_location"
    debug_log "[DB EXPORT] domain=$domain"
    debug_log "[DB EXPORT] backup_dir=$backup_dir"

    # Ensure MariaDB container is running
    if ! core_mysql_check_running; then
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    fi

    # Start database export using mysqldump
    print_msg step "$(printf "$STEP_BACKUP_DATABASE" "$db_name")"
    debug_log "[Backup] Running mysqldump for: $db_name → $save_location"

    if ! docker exec --env MYSQL_PWD="$db_password" "$MYSQL_CONTAINER_NAME" \
        mysqldump -u"$db_user" "$db_name" >"$save_location"; then
        print_msg error "$(printf "$ERROR_BACKUP_DB_DUMP_FAILED" "$db_name")"
        return 1
    fi

    print_msg success "$SUCCESS_BACKUP_RESTORED_DB: $db_name"

    # Display backup metadata
    local file_name file_size file_time
    file_name="$(basename "$save_location")"
    file_size="$(du -sh "$save_location" | cut -f1)"

    if [[ "$(uname)" == "Darwin" ]]; then
        file_time=$(stat -f %SB -t "%Y-%m-%d %H:%M:%S" "$save_location")
    else
        file_time=$(stat -c %y "$save_location")
    fi

    echo ""
    print_msg info "📦 File Name: $file_name"
    print_msg info "📐 File Size: $file_size"
    print_msg info "🕒 File Creation Time: $file_time"
    print_msg info "💾 Saved at: $save_location"

    echo "$save_location"
}