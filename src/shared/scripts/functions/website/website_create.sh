#!/bin/bash
#shellcheck disable=SC2317
# ==================================================
# File: website_create.sh
# Description: Functions to create and configure a new WordPress website, including:
#              - Prompting the user for domain and PHP version.
#              - Setting up site directories, nginx, SSL, and Docker containers.
#              - Applying permissions and reloading nginx.
# Functions:
#   - website_prompt_create: Prompt user for domain and PHP version, then call website_cli_create.
#       Parameters: None.
#   - website_logic_create: Main logic to create and configure a new WordPress website.
#       Parameters:
#           $1 - domain: Domain name of the website.
#           $2 - php_version: PHP version to use for the website.
# ==================================================

website_prompt_create() {
    # Prompt user for domain and PHP version, then call website_cli_create.
    # Parameters: None.

    print_msg title "$TITLE_CREATE_NEW_WORDPRESS_WEBSITE"
    read -p "$PROMPT_ENTER_DOMAIN: " domain
    _is_valid_domain "$domain" || return 1
    php_prompt_choose_version || return 1
    php_version="$SELECTED_PHP"

    echo ""
    choice=$(get_input_or_test_value "$PROMPT_WEBSITE_CREATE_RANDOM_ADMIN" "${TEST_WEBSITE_CREATE_RANDOM_ADMIN:-y}")
    choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]')"

    auto_generate=true
    [[ "$choice" == "n" ]] && auto_generate=false

    print_and_debug "🐝 PHP version: $php_version"
    print_and_debug "🐝 Domain: $domain"

    website_cli_create \
        --domain="$domain" \
        --php="$php_version" \
        --auto_generate="$auto_generate" || return 1
}

website_logic_create() {
    # Main logic to create and configure a new WordPress website.
    # Parameters:
    #   $1 - domain: Domain name of the website.
    #   $2 - php_version: PHP version to use for the website.

    local domain="$1"
    local php_version="$2"
    export domain php_version
    _is_valid_domain "$domain" || return 1
    SITE_DIR="$SITES_DIR/$domain"
    website_set_config "$domain" "$php_version"
    CONTAINER_PHP=$(json_get_site_value "$domain" "CONTAINER_PHP")

    # Cleanup function to handle errors and rollback changes.
    cleanup() {
        print_msg cancel "$MSG_CLEANING_UP"

        if docker ps -a --filter "name=${CONTAINER_PHP}" --format '{{.Names}}' | grep -q "${CONTAINER_PHP}"; then
            docker rm -f "$CONTAINER_PHP" &>/dev/null
            print_and_debug success "$SUCCESS_CONTAINER_STOP: $CONTAINER_PHP"
        fi

        if [[ -d "$SITE_DIR" ]]; then
            rm -rf "$SITE_DIR"
            print_msg success "$SUCCESS_DIRECTORY_REMOVE: $SITE_DIR"
        fi

        if [[ -f "$NGINX_PROXY_DIR/conf.d/${domain}.conf" ]]; then
            rm -f "$NGINX_PROXY_DIR/conf.d/${domain}.conf"
            print_msg success "$SUCCESS_FILE_REMOVE: $NGINX_PROXY_DIR/conf.d/${domain}.conf"
        fi

        if [[ -f "$SSL_DIR/$domain.crt" ]]; then
            rm -f "$SSL_DIR/$domain.crt"
        fi
        if [[ -f "$SSL_DIR/$domain.key" ]]; then
            rm -f "$SSL_DIR/$domain.key"
        fi

        json_delete_site_key "$domain"
        print_msg info "🔁 Rollback complete."
    }

    trap cleanup ERR

    if _is_directory_exist "$SITE_DIR" false; then
        print_msg cancel "$MSG_WEBSITE_EXISTS: $domain"
        return 1
    fi

    run_cmd "mkdir -p '$SITE_DIR/php' '$SITE_DIR/mariadb/conf.d' '$SITE_DIR/wordpress' '$SITE_DIR/logs' '$SITE_DIR/backups'"
    run_cmd "touch '$SITE_DIR/logs/access.log' '$SITE_DIR/logs/error.log'"
    run_cmd "touch '$SITE_DIR/logs/php_error.log'"
    run_cmd "touch '$SITE_DIR/logs/php_slow.log'"
    run_cmd "chmod 666 '$SITE_DIR/logs/'*.log"

    TEMPLATE_VERSION_FILE="$TEMPLATES_DIR/.template_version"
    if _is_file_exist "$TEMPLATE_VERSION_FILE"; then
        copy_file "$TEMPLATE_VERSION_FILE" "$SITE_DIR/.template_version"
        print_msg copy "$SUCCESS_COPY $TEMPLATE_VERSION_FILE → $SITE_DIR/.template_version"
    else
        print_msg warning "$MSG_NOT_FOUND: $TEMPLATE_VERSION_FILE"
    fi

    print_msg step "$STEP_WEBSITE_SETUP_NGINX: $domain"
    nginx_add_mount_docker "$domain"
    website_setup_nginx "$domain"

    print_msg step "$STEP_WEBSITE_SETUP_COPY_CONFIG: $domain"
    copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini"

    print_msg step "$STEP_WEBSITE_SETUP_APPLY_CONFIG: $domain"
    create_optimized_php_fpm_config "$domain"

    print_msg step "$STEP_WEBSITE_SETUP_CREATE_ENV: $domain"

    print_msg step "$STEP_WEBSITE_SETUP_CREATE_SSL: $domain"
    ssl_logic_install_selfsigned "$domain"

    print_msg step "$STEP_WEBSITE_SETUP_CREATE_DOCKER_COMPOSE: $domain"
    website_generate_docker_compose "$domain"

    print_msg step "$MSG_START_CONTAINER: $domain"
    run_in_dir "$SITE_DIR" docker compose up -d || {
        print_msg error "$ERROR_COMMAND_FAILED: docker compose up -d"
        return 1
    }

    print_msg step "$MSG_CHECKING_CONTAINER"
    debug_log "  ➤ CONTAINER_PHP: $CONTAINER_PHP"

    if ! _is_container_running "$CONTAINER_PHP"; then
        print_msg error "$ERROR_CONTAINER_NOT_READY_AFTER_30S"
        return 1
    fi

    print_msg success "$MSG_CONTAINER_READY"

    print_msg step "$MSG_DOCKER_NGINX_RESTART"
    nginx_reload

    print_msg step "$MSG_WEBSITE_PERMISSIONS: $domain"
    run_cmd "docker exec -u root '$CONTAINER_PHP' chown -R nobody:nogroup /var/www/"
    debug_log "✅ website_logic_create completed"

    trap - ERR
}