website_management_create_logic() {
    local domain="$1"
    local php_version="$2"

    SITE_DIR="$SITES_DIR/$domain"
    CONTAINER_PHP="${domain}${PHP_CONTAINER_SUFFIX}"
    CONTAINER_DB="${domain}${DB_CONTAINER_SUFFIX}"
    MARIADB_VOLUME="${domain//./}${DB_VOLUME_SUFFIX}"
    LOG_FILE="$LOGS_DIR/${domain}-setup.log"

    cleanup() {
        print_msg cancel "$MSG_CLEANING_UP"
        if [[ -d "$SITE_DIR" ]]; then
            run_cmd "rm -rf '$SITE_DIR'"
            print_msg success "$SUCCESS_DIRECTORY_REMOVE: $SITE_DIR"
        fi
        if docker ps -a --filter "name=${CONTAINER_PHP}" --format '{{.Names}}' | grep -q "${CONTAINER_PHP}"; then
            run_cmd "docker stop '$CONTAINER_PHP' && docker rm '$CONTAINER_PHP'"
            print_and_debug success "$SUCCESS_CONTAINER_STOP: $CONTAINER_PHP"
        fi
        if docker ps -a --filter "name=${CONTAINER_DB}" --format '{{.Names}}' | grep -q "${CONTAINER_DB}"; then
            run_cmd "docker stop '$CONTAINER_DB' && docker rm '$CONTAINER_DB'"
            print_and_debug success "$SUCCESS_CONTAINER_STOP: $CONTAINER_DB"
        fi
        if docker volume ls --format '{{.Name}}' | grep -q "$MARIADB_VOLUME"; then
            run_cmd "docker volume rm '$MARIADB_VOLUME'"
            print_and_debug success "$SUCCESS_CONTAINER_VOLUME_REMOVE: $MARIADB_VOLUME"
        fi
        if [[ -d "$SSL_DIR" ]]; then
            run_cmd "rm -rf '$SSL_DIR'"
            print_and_debug success "$SUCCESS_DIRECTORY_REMOVE: $SSL_DIR"
        fi
    }

    trap '
    err_func="${FUNCNAME[1]:-MAIN}"
    err_line="${BASH_LINENO[0]}"
    print_and_debug error "$ERROR_TRAP_LOG: $err_func (line $err_line)"
    cleanup
    ' ERR SIGINT

    if is_directory_exist "$SITE_DIR" false; then
        print_msg cancel "$MSG_WEBSITE_EXISTS: $domain"
        return 1
    fi

    if docker volume ls --format '{{.Name}}' | grep -q "^$MARIADB_VOLUME$"; then
        print_msg warning "$MSG_DOCKER_VOLUME_FOUND: $MARIADB_VOLUME"
        run_cmd "docker volume rm '$MARIADB_VOLUME'"
    fi

    run_cmd "mkdir -p '$SITE_DIR/php' '$SITE_DIR/mariadb/conf.d' '$SITE_DIR/wordpress' '$SITE_DIR/logs' '$SITE_DIR/backups'"
    run_cmd "touch '$SITE_DIR/logs/access.log' '$SITE_DIR/logs/error.log'"
    run_cmd "chmod 666 '$SITE_DIR/logs/'*.log"

    TEMPLATE_VERSION_FILE="$TEMPLATES_DIR/.template_version"
    if is_file_exist "$TEMPLATE_VERSION_FILE"; then
        copy_file "$TEMPLATE_VERSION_FILE" "$SITE_DIR/.template_version"
        print_msg copy "$SUCCESS_COPY $TEMPLATE_VERSION_FILE → $SITE_DIR/.template_version"
    else
        print_msg warning "$MSG_NOT_FOUND: $TEMPLATE_VERSION_FILE"
    fi

    print_msg step "$STEP_WEBSITE_SETUP_NGINX: $domain"
    nginx_add_mount_docker "$domain"
    export domain php_version
    website_setup_nginx

    print_msg step "$STEP_WEBSITE_SETUP_COPY_CONFIG: $domain"
    copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini"

    print_msg step "$STEP_WEBSITE_SETUP_APPLY_CONFIG: $domain"
    apply_mariadb_config "$SITE_DIR/mariadb/conf.d/custom.cnf"
    create_optimized_php_fpm_config "$SITE_DIR/php/php-fpm.conf"

    print_msg step "$STEP_WEBSITE_SETUP_CREATE_ENV: $domain"
    website_create_env "$SITE_DIR" "$domain" "$php_version"

    print_msg step "$STEP_WEBSITE_SETUP_CREATE_SSL: $domain"
    generate_ssl_cert "$domain" "$SSL_DIR"

    print_msg step "$STEP_WEBSITE_SETUP_CREATE_DOCKER_COMPOSE: $domain"
    TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
    TARGET_FILE="$SITE_DIR/docker-compose.yml"
    if is_file_exist "$TEMPLATE_FILE"; then
        set -o allexport && source "$SITE_DIR/.env" && set +o allexport
        php_version="$php_version" envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE"
        print_msg success "$MSG_CREATED: $TARGET_FILE"
    else
        print_msg error "$MSG_NOT_FOUND: $TEMPLATE_FILE"
        exit 1
    fi

    print_msg step "$MSG_START_CONTAINER: $domain"
    run_in_dir "$SITE_DIR" docker compose up -d || {
        print_msg error "$ERROR_COMMAND_FAILED: docker compose up -d"
        return 1
    }
    print_msg progress "$MSG_CHECKING_CONTAINER"

    debug_log "  ➤ CONTAINER_PHP: $CONTAINER_PHP"
    debug_log "  ➤ CONTAINER_DB: $CONTAINER_DB"

    if ! is_container_running "$CONTAINER_PHP" "$CONTAINER_DB"; then
        stop_loading
        print_msg error "$ERROR_CONTAINER_NOT_READY_AFTER_30S"
        return 1
    fi
    stop_loading
    print_msg success "$MSG_CONTAINER_READY"

    print_msg step "$MSG_DOCKER_NGINX_RESTART"
    nginx_restart

    print_msg step "$MSG_WEBSITE_PERMISSIONS: $domain"
    run_cmd "docker exec -u root '$CONTAINER_PHP' chown -R nobody:nogroup /var/www/"
    debug_log "✅ website_management_create_logic completed"
}