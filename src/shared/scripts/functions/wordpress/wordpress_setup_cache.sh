# -----------------------------------------------------------------------------
# Function: wordpress_cache_setup_logic
# Purpose: Configures caching for a WordPress site, including plugin management,
#          NGINX configuration, and cache type setup.
#
# Parameters:
#   1. domain (string): The domain of the WordPress site.
#   2. cache_type (string): The type of cache to configure. Supported values:
#      - "no-cache": Disables caching and removes cache plugins.
#      - "wp-super-cache": Configures WP Super Cache plugin.
#      - "fastcgi-cache": Configures FastCGI caching with NGINX Helper plugin.
#      - "w3-total-cache": Configures W3 Total Cache plugin.
#      - "wp-fastest-cache": Configures WP Fastest Cache plugin.
#
# Description:
#   - Ensures the site directory exists.
#   - Deactivates any active cache plugins.
#   - Handles "no-cache" option by removing cache plugins, disabling WP_CACHE,
#     and updating NGINX configuration.
#   - Updates NGINX configuration to include the appropriate cache settings.
#   - Installs and activates the specified cache plugin.
#   - Configures additional settings for FastCGI and Redis caching if applicable.
#   - Reloads NGINX to apply changes.
#   - Provides instructions for completing the setup of specific cache plugins.
#
# Dependencies:
#   - Requires Docker and WordPress CLI (wp-cli) to be installed and accessible.
#   - Assumes specific environment variables are set:
#     - SITES_DIR: Base directory for WordPress sites.
#     - NGINX_PROXY_DIR: Directory for NGINX proxy configurations.
#     - PHP_CONTAINER: Name of the PHP container for the site.
#     - PHP_CONTAINER_WP_PATH: Path to WordPress installation in the PHP container.
#     - NGINX_MAIN_CONF: Path to the main NGINX configuration file.
#     - PHP_USER: User owning the WordPress files in the PHP container.
#
# Returns:
#   - 0 on success.
#   - 1 on failure, with an appropriate error message.
#
# Example Usage:
#   wordpress_cache_setup_logic "example.com" "wp-super-cache"
# -----------------------------------------------------------------------------
wordpress_cache_setup_logic() {
    local domain="$1"
    local cache_type="$2"
    local site_dir="$SITES_DIR/$domain"
    local wp_config_file="$site_dir/wordpress/wp-config.php"
    local nginx_conf_file="$NGINX_PROXY_DIR/conf.d/${domain}.conf"
    local PHP_CONTAINER="$domain-php"

    if [[ ! -d "$site_dir" ]]; then
        print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$site_dir")"
        return 1
    fi

    local cache_plugins=("wp-super-cache" "nginx-helper" "w3-total-cache" "redis-cache" "wp-fastest-cache")
    local active_plugins
    active_plugins=$(docker_exec_php "wp plugin list --status=active --field=name --path=$PHP_CONTAINER_WP_PATH")

    for plugin in "${cache_plugins[@]}"; do
        if echo "$active_plugins" | grep -q "$plugin"; then
            print_msg warning "$(printf "$WARNING_PLUGIN_ACTIVE_DEACTIVATING" "$plugin")"
            if docker_exec_php "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH"; then
                print_msg success "$(printf "$SUCCESS_PLUGIN_DEACTIVATED" "$plugin")"
            else
                print_and_debug error "$(printf "$ERROR_PLUGIN_DEACTIVATION" "$plugin")"
            fi
        fi
    done

    if [[ "$cache_type" == "no-cache" ]]; then
        print_msg warning "$WARNING_CACHE_REMOVING"
        for plugin in "${cache_plugins[@]}"; do
            if echo "$active_plugins" | grep -q "$plugin"; then
                print_msg warning "$(printf "$WARNING_PLUGIN_ACTIVE_DELETING" "$plugin")"
                if docker_exec_php "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH" && \
                   docker_exec_php "wp plugin delete $plugin --path=$PHP_CONTAINER_WP_PATH"; then
                    print_msg success "$(printf "$SUCCESS_PLUGIN_DELETED" "$plugin")"
                else
                    print_and_debug error "$(printf "$ERROR_PLUGIN_DELETION" "$plugin")"
                    return 1
                fi
            fi
        done

        if ! sedi "/define('WP_CACHE', true);/d" "$wp_config_file"; then
            print_and_debug error "$ERROR_REMOVE_WP_CACHE_DEFINE"
            return 1
        fi

        if grep -q "include /etc/nginx/cache/" "$nginx_conf_file"; then
            if ! sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/no-cache.conf;|" "$nginx_conf_file"; then
                print_and_debug error "$ERROR_UPDATE_NGINX_NO_CACHE"
                return 1
            fi
        fi

        nginx_reload || {
            print_and_debug error "$ERROR_NGINX_RELOAD"
            return 1
        }

        print_msg success "$SUCCESS_CACHE_DISABLED"
        return 0
    fi

    if grep -q "include /etc/nginx/cache/" "$nginx_conf_file"; then
        sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/${cache_type}.conf;|" "$nginx_conf_file"
        exit_if_error $? "$ERROR_UPDATE_NGINX_CACHE_TYPE"
        print_msg success "$(printf "$SUCCESS_UPDATE_NGINX_CACHE_TYPE" "$cache_type")"
    else
        print_and_debug error "$ERROR_NGINX_INCLUDE_NOT_FOUND"
        return 1
    fi

    local plugin_slug
    case "$cache_type" in
        "wp-super-cache") plugin_slug="wp-super-cache" ;;
        "fastcgi-cache") plugin_slug="nginx-helper" ;;
        "w3-total-cache") plugin_slug="w3-total-cache" ;;
        "wp-fastest-cache") plugin_slug="wp-fastest-cache" ;;
    esac

    bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin install "$plugin_slug" --activate
    exit_if_error $? "$(printf "$ERROR_PLUGIN_INSTALL" "$plugin_slug")"

    docker exec -u root -i "$PHP_CONTAINER" chown -R "$PHP_USER" /var/www/html/wp-content
    exit_if_error $? "$ERROR_CHOWN_WPCONTENT"

    if [[ "$cache_type" == "fastcgi-cache" || "$cache_type" == "w3-total-cache" ]]; then
        if ! grep -q "fastcgi_cache_path" "$NGINX_MAIN_CONF"; then
            sedi "/http {/a\\
fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;" "$NGINX_MAIN_CONF"
            exit_if_error $? "$ERROR_ADD_FASTCGI_PATH"
            print_msg success "$SUCCESS_FASTCGI_PATH_ADDED"
        fi

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- option update rt_wp_nginx_helper_options '{"enable_purge":true}' --format=json
        exit_if_error $? "$ERROR_UPDATE_NGINX_HELPER"
    fi

    if [[ "$cache_type" == "fastcgi-cache" ]]; then
        if ! grep -q "WP_REDIS_HOST" "$wp_config_file"; then
            sedi "/<?php/a\\
define('WP_REDIS_HOST', 'redis-cache');\\
define('WP_REDIS_PORT', 6379);\\
define('WP_REDIS_DATABASE', 0);" "$wp_config_file"
        fi

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin install redis-cache --activate
        exit_if_error $? "$ERROR_REDIS_PLUGIN_INSTALL"

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- redis update-dropin
        exit_if_error $? "$ERROR_REDIS_UPDATE_DROPIN"

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- option update redis-cache
        exit_if_error $? "$ERROR_REDIS_UPDATE_OPTIONS"

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- redis enable
        exit_if_error $? "$ERROR_REDIS_ENABLE"
    fi

    nginx_reload
    exit_if_error $? "$ERROR_NGINX_RELOAD"
    print_msg success "$SUCCESS_NGINX_RELOADED"

    case "$cache_type" in
        "wp-super-cache") print_msg info "$TIP_WP_SUPER_CACHE" ;;
        "w3-total-cache") print_msg info "$TIP_W3_TOTAL_CACHE" ;;
        "wp-fastest-cache") print_msg info "$TIP_WP_FASTEST_CACHE" ;;
    esac
}