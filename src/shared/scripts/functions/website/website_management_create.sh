website_management_create_logic() {
    local domain="$1"
    local php_version="$2"

    SITE_DIR="$SITES_DIR/$domain"  # Use domain for directory naming
    CONTAINER_PHP="${domain}${PHP_CONTAINER_SUFFIX}"
    CONTAINER_DB="${domain}${DB_CONTAINER_SUFFIX}"
    MARIADB_VOLUME="${domain//./}${DB_VOLUME_SUFFIX}"
    LOG_FILE="$LOGS_DIR/${domain}-setup.log"
    
    # Function to clean up resources in case of error
    cleanup() {
        print_msg cancel "$MSG_CLEANING_UP"
        # Remove any files or directories that were created
        if [[ -d "$SITE_DIR" ]]; then
            run_cmd "rm -rf $SITE_DIR"
            print_msg success "$SUCCESS_DIRECTORY_REMOVE: $SITE_DIR"
        fi
        if docker ps -a --filter "name=${CONTAINER_PHP}" --format '{{.Names}}' | grep -q "${CONTAINER_PHP}"; then
            run_cmd "docker stop $CONTAINER_PHP && docker rm $CONTAINER_PHP" true
            print_and_debug success "$SUCCESS_CONTAINER_STOP: $CONTAINER_PHP"
        fi
        if docker ps -a --filter "name=${CONTAINER_DB}" --format '{{.Names}}' | grep -q "${CONTAINER_DB}"; then
            #docker stop "$CONTAINER_DB" && docker rm "$CONTAINER_DB"
            run_cmd "docker stop $CONTAINER_DB && docker rm $CONTAINER_DB" true
            print_and_debug success "$SUCCESS_CONTAINER_STOP: $CONTAINER_DB"
        fi
        if docker volume ls --format '{{.Name}}' | grep -q "$MARIADB_VOLUME"; then
            #docker volume rm "$MARIADB_VOLUME"
            run_cmd "docker volume rm $MARIADB_VOLUME" true
            print_and_debug success "$SUCCESS_CONTAINER_VOLUME_REMOVE: $MARIADB_VOLUME"
        fi
        if [[ -d "$SSL_DIR" ]]; then
            rm -rf "$SSL_DIR"
            #echo "Removed SSL directory: $SSL_DIR"
            print_and_debug success "$SUCCESS_DIRECTORY_REMOVE: $SSL_DIR"
        fi
    }

    # Trap to catch errors and execute cleanup function
    trap '
    err_func="${FUNCNAME[1]:-MAIN}"
    err_line="${BASH_LINENO[0]}"
    print_and_debug error "$ERROR_TRAP_LOG: $err_func (line $err_line)"
    cleanup
    ' ERR SIGINT
    
    
    # Check if site already exists
    if is_directory_exist "$SITE_DIR" false; then
        #echo -e "${RED}${CROSSMARK} Website '$domain' already exists.${NC}"
        print_msg cancel "$MSG_WEBSITE_EXISTS: $domain"
        return 1
    fi

    # 🧹 Remove existing volume if exists
    if docker volume ls --format '{{.Name}}' | grep -q "^$MARIADB_VOLUME$"; then
        print_msg warning "$MSG_DOCKER_VOLUME_FOUND: $MARIADB_VOLUME"
        run_cmd "docker volume rm $MARIADB_VOLUME" true
    fi

    # 🗘️ Create log and directory structure
    mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
    touch "$SITE_DIR/logs/access.log" "$SITE_DIR/logs/error.log"
    chmod 666 "$SITE_DIR/logs/"*.log

    # Copy .template_version file if exists
    TEMPLATE_VERSION_FILE="$TEMPLATES_DIR/.template_version"
    if is_file_exist "$TEMPLATE_VERSION_FILE"; then
        run_cmd "cp \"$TEMPLATE_VERSION_FILE\" \"$SITE_DIR/.template_version\""
        
        print_msg copy "$SUCCESS_COPY $TEMPLATE_VERSION_FILE → $SITE_DIR/.template_version"
    else
        print_msg warning "$MSG_NOT_FOUND: $TEMPLATE_VERSION_FILE"
    fi

    # 🔧 Configure NGINX
    print_msg step "$STEP_WEBSITE_SETUP_NGINX: $domain"
    run_cmd "nginx_add_mount_docker \"$domain\"" true
    export domain php_version
    run_cmd "website_setup_nginx" true
    # ⚙️ Create configurations
    print_msg step "$STEP_WEBSITE_SETUP_COPY_CONFIG: $domain"
    run_cmd "copy_file \"$TEMPLATES_DIR/php.ini.template\" \"$SITE_DIR/php/php.ini\"" true
    
    print_msg step "$STEP_WEBSITE_SETUP_APPLY_CONFIG: $domain"
    run_cmd "apply_mariadb_config \"$SITE_DIR/mariadb/conf.d/custom.cnf\"" true
    run_cmd "create_optimized_php_fpm_config \"$SITE_DIR/php/php-fpm.conf\"" true
    
    print_msg step "$STEP_WEBSITE_SETUP_CREATE_ENV: $domain"
    run_cmd "website_create_env \"$SITE_DIR\" \"$domain\" \"$php_version\"" true

    print_msg step "$STEP_WEBSITE_SETUP_CREATE_SSL: $domain"
    run_cmd "generate_ssl_cert \"$domain\" \"$SSL_DIR\"" true
    
    # 🛠️ Create docker-compose.yml
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

    # 🚀 Start containers
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
    
    # 🔁 Restart NGINX
    print_msg step "$MSG_DOCKER_NGINX_RESTART"
    nginx_restart

    # 🧑‍💻 Permissions
    print_msg step "$MSG_WEBSITE_PERMISSIONS: $domain"
    run_cmd "docker exec -u root $CONTAINER_PHP chown -R nobody:nogroup /var/www/"
    debug_log "✅ website_management_create_logic completed"
}