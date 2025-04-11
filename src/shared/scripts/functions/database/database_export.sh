#shellcheck disable=SC1091
#source "$CLI_DIR/database_actions.sh"

database_prompt_export() {
    # Ensure SITE_DOMAIN is set by calling select_website
    echo "🔧 Choose the website for backup:"
    select_website || exit 1

    # Check if SITE_DOMAIN is still empty
    if [[ -z "$domain" ]]; then
        echo "${CROSSMARK} Site name is not set. Exiting..."
        exit 1
    fi
    echo "💾 Backup will be saved to: $save_location"

    database_export_logic --domain="$domain" --save_location="$save_location"
}

database_export_logic() {
    local domain="$1"
    local save_location="$2"

    if [[ -z "$SITES_DIR" ]]; then
        print_msg error "$ERROR_CONFIG_SITES_DIR_NOT_SET"
        return 1
    fi

    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_PARAM_SITE_NAME_REQUIRED"
        return 1
    fi

    local backup_dir
    backup_dir="$(dirname "$save_location")"
    if [[ ! -d "$backup_dir" ]]; then
        print_msg warning "$(printf "$WARNING_BACKUP_DIR_NOT_EXIST_CREATE" "$backup_dir")"
        mkdir -p "$backup_dir" || {
            print_msg error "$ERROR_BACKUP_CREATE_DIR_FAILED"
            return 1
        }
    fi

    local db_name db_user db_password
    db_name="$(json_get_site_value "$domain" "MYSQL_DATABASE")"
    db_user="$(json_get_site_value "$domain" "MYSQL_USER")"
    db_password="$(json_get_site_value "$domain" "MYSQL_PASSWORD")"
    debug_log "[DB IMPORT] db_name=$db_name, db_user=$db_user"

    if ! is_mariadb_running "$domain"; then
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    fi

    print_msg step "$(printf "$STEP_BACKUP_DATABASE" "$db_name")"
    debug_log "[Backup] Running mysqldump for: $db_name → $save_location"

    local db_container
    db_container=$(json_get_site_value "$domain" "CONTAINER_DB")
    if [[ -z "$db_container" ]]; then
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_DEFINED"
        return 1
    fi

    if ! docker exec --env MYSQL_PWD="$db_password" "$db_container" \
        mysqldump -u"$db_user" "$db_name" >"$save_location"; then
        print_msg error "$(printf "$ERROR_BACKUP_DB_DUMP_FAILED" "$db_name")"
        return 1
    fi

    print_msg success "$SUCCESS_BACKUP_RESTORED_DB: $db_name"

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
