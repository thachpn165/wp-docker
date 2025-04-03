website_management_create_logic() {
    local domain="$1"
    local php_version="$2"

    SITE_DIR="$SITES_DIR/$domain"  # Use domain for directory naming
    CONTAINER_PHP="${domain}-php"  # Container name using domain
    CONTAINER_DB="${domain}-mariadb"
    MARIADB_VOLUME="${domain//./}_mariadb_data"
    LOG_FILE="$LOGS_DIR/${domain}-setup.log"
    
    # Function to clean up resources in case of error
    cleanup() {
        echo "⚠️ Cleaning up..."
        # Remove any files or directories that were created
        if [[ -d "$SITE_DIR" ]]; then
            rm -rf "$SITE_DIR"
            echo "Removed site directory: $SITE_DIR"
        fi
        if docker ps -a --filter "name=${CONTAINER_PHP}" --format '{{.Names}}' | grep -q "${CONTAINER_PHP}"; then
            docker stop "$CONTAINER_PHP" && docker rm "$CONTAINER_PHP"
            echo "Stopped and removed container: $CONTAINER_PHP"
        fi
        if docker ps -a --filter "name=${CONTAINER_DB}" --format '{{.Names}}' | grep -q "${CONTAINER_DB}"; then
            docker stop "$CONTAINER_DB" && docker rm "$CONTAINER_DB"
            echo "Stopped and removed container: $CONTAINER_DB"
        fi
        if docker volume ls --format '{{.Name}}' | grep -q "$MARIADB_VOLUME"; then
            docker volume rm "$MARIADB_VOLUME"
            echo "Removed MariaDB volume: $MARIADB_VOLUME"
        fi
        if [[ -d "$SSL_DIR" ]]; then
            rm -rf "$SSL_DIR"
            echo "Removed SSL directory: $SSL_DIR"
        fi
    }

    # Trap to catch errors and execute cleanup function
    trap cleanup ERR

    # Check if site already exists
    if is_directory_exist "$SITE_DIR" false; then
        echo -e "${RED}${CROSSMARK} Website '$domain' already exists.${NC}"
        return 1
    fi

    # 🧹 Remove existing volume if exists
    if docker volume ls --format '{{.Name}}' | grep -q "^$MARIADB_VOLUME$"; then
        echo -e "${YELLOW}${WARNING} Existing MariaDB volume '$MARIADB_VOLUME' found. Removing to ensure clean setup...${NC}"
        docker volume rm "$MARIADB_VOLUME"
    fi

    # 🗘️ Create log and directory structure
    mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
    touch "$SITE_DIR/logs/access.log" "$SITE_DIR/logs/error.log"
    chmod 666 "$SITE_DIR/logs/"*.log

    # Copy .template_version file if exists
    TEMPLATE_VERSION_FILE="$TEMPLATES_DIR/.template_version"
    if is_file_exist "$TEMPLATE_VERSION_FILE"; then
        cp "$TEMPLATE_VERSION_FILE" "$SITE_DIR/.template_version"
        echo -e "${GREEN}${CHECKMARK} Copied .template_version to $SITE_DIR${NC}"
    else
        echo -e "${YELLOW}${WARNING} No .template_version file found in shared/templates.${NC}"
    fi

    # 🔧 Configure NGINX
    nginx_add_mount_docker "$domain" || return 1
    export domain php_version
    bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh" || return 1

    # ⚙️ Create configurations
    copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini" || return 1
    apply_mariadb_config "$SITE_DIR/mariadb/conf.d/custom.cnf" || return 1
    create_optimized_php_fpm_config "$SITE_DIR/php/php-fpm.conf" || return 1
    website_create_env "$SITE_DIR" "$domain" "$php_version" || return 1

    # SSL
    generate_ssl_cert "$domain" "$SSL_DIR" || return 1
    # 🛠️ Create docker-compose.yml
    TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
    TARGET_FILE="$SITE_DIR/docker-compose.yml"
    if is_file_exist "$TEMPLATE_FILE"; then
        set -o allexport && source "$SITE_DIR/.env" && set +o allexport
        envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE" || return 1
        echo -e "${GREEN}${CHECKMARK} Created docker-compose.yml${NC}"
    else
        echo -e "${RED}${CROSSMARK} docker-compose.yml template not found${NC}"
        return 1
    fi

    # 🚀 Start containers
    run_in_dir "$SITE_DIR" \
        docker compose up -d || return 1

    echo -e "${YELLOW}⏳ Checking container startup...${NC}"
    for i in {1..30}; do
        if is_container_running "$CONTAINER_PHP" && is_container_running "$CONTAINER_DB"; then
            echo -e "${GREEN}${CHECKMARK} Container is ready.${NC}"
            break
        fi
        sleep 1
    done

    if ! is_container_running "$CONTAINER_PHP" || ! is_container_running "$CONTAINER_DB"; then
        echo -e "${RED}${CROSSMARK} Container not ready after 30 seconds.${NC}"
        return 1
    fi

    # 🔁 Restart NGINX
    nginx_restart || return 1

    # 🧑‍💻 Permissions
    if is_container_running "$CONTAINER_PHP"; then
        docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup /var/www/ || return 1
    else
        echo -e "${YELLOW}${WARNING} Container PHP not running, skipping permissions.${NC}"
    fi
}