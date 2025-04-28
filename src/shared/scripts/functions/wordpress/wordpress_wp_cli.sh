#!/bin/bash

# =====================================
# wordpress_wp_cli_logic: Execute WP-CLI command inside the PHP container of a site
# Parameters:
#   $1 - domain (site name)
#   $* - wp-cli command (e.g. "plugin list", "user update ...")
# Behavior:
#   - Detects PHP container for the site
#   - Ensures container is running
#   - Executes WP-CLI as correct user inside container
# =====================================
wordpress_wp_cli_logic() {
    local domain="$1"
    shift
    local wp_command="$*"

    _is_missing_param "$domain" "domain" || return 1
    _is_missing_param "$wp_command" "wp_command" || return 1
    _is_valid_domain "$domain" || return 1


    local php_container
    php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")

    if [[ -z "$php_container" ]]; then
        print_and_debug error "$ERROR_DOCKER_PHP_CONTAINER_NOT_FOUND: $domain"
        return 1
    fi

    local user="${PHP_USER:-nobody}"

    if ! docker ps --format '{{.Names}}' | grep -q "^$php_container$"; then
        print_and_debug error "❌ PHP container '$php_container' is not running."
        return 1
    fi

    docker exec \
        -e WP_CLI_CACHE_DIR=/tmp/wp-cli-cache \
        -u "$user" \
        "$php_container" \
        wp $wp_command --path=/var/www/html
}