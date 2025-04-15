wordpress_prompt_cache_setup() {
    safe_source "$CLI_DIR/wordpress_cache_setup.sh"
    # 📋 Hiển thị danh sách website để chọn (dùng select_website)

    select_website
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_NO_WEBSITE_SELECTED"
        exit 1
    fi

    # === Cache Type Selection ===
    print_msg title "$LABEL_MENU_MAIN_WORDPRESS_CACHE"
    print_msg info "  ${GREEN}[1]${NC} WP Super Cache"
    print_msg info "  ${GREEN}[2]${NC} FastCGI Cache"
    print_msg info "  ${GREEN}[3]${NC} W3 Total Cache"
    print_msg info "  ${GREEN}[4]${NC} WP Fastest Cache"
    print_msg info "  ${GREEN}[5]${NC} No Cache"

    cache_type_index=$(get_input_or_test_value "$PROMPT_WORDPRESS_CHOOSE_CACHE" "${TEST_CACHE_TYPE:-5}")

    # Validate selection
    case $cache_type_index in
    1) cache_type="wp-super-cache" ;;
    2) cache_type="fastcgi-cache" ;;
    3) cache_type="w3-total-cache" ;;
    4) cache_type="wp-fastest-cache" ;;
    5) cache_type="no-cache" ;;
    *) print_msg error "$ERROR_SELECT_OPTION_INVALID" && exit 1 ;;
    esac

    print_msg success "$SUCCESS_WORDPRESS_CHOOSE_CACHE: $cache_type"

    # Call the logic function to set up the cache
    wordpress_cli_cache_setup "$domain" "$cache_type"
}
# =====================================
# wordpress_cache_setup_logic: Setup or remove caching configuration for a WordPress site
# Parameters:
#   $1 - domain
#   $2 - cache_type (e.g. wp-super-cache, fastcgi-cache, w3-total-cache, no-cache)
# Behavior:
#   - Deactivates existing cache plugins
#   - Removes WP_CACHE define and plugins if no-cache
#   - Updates nginx config to use selected cache strategy
#   - Installs required plugin and helper options if needed
# =====================================
wordpress_cache_setup_logic() {
    local domain="$1"
    local cache_type="$2"
    local site_dir="$SITES_DIR/$domain"
    local wp_config_file="$site_dir/wordpress/wp-config.php"
    local nginx_conf_file="$NGINX_PROXY_DIR/conf.d/${domain}.conf"
    local php_container
    php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")

    if [[ ! -d "$site_dir" ]]; then
        print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$site_dir")"
        return 1
    fi

    local cache_plugins=("wp-super-cache" "nginx-helper" "w3-total-cache" "redis-cache" "wp-fastest-cache")
    local active_plugins
    active_plugins=$(wordpress_wp_cli_logic "$domain" "plugin list --status=active --field=name --path=$PHP_CONTAINER_WP_PATH")

    for plugin in "${cache_plugins[@]}"; do
        if echo "$active_plugins" | grep -q "$plugin"; then
            print_msg warning "$(printf "$WARNING_PLUGIN_ACTIVE_DEACTIVATING" "$plugin")"
            if docker_exec_php "$domain" "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH"; then
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
                if docker_exec_php "$domain" "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH" &&
                    docker_exec_php "$domain" "wp plugin delete $plugin --path=$PHP_CONTAINER_WP_PATH"; then
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

    bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- plugin install "$plugin_slug" --activate
    exit_if_error $? "$(printf "$ERROR_PLUGIN_INSTALL" "$plugin_slug")"

    docker exec -u root -i "$php_container" chown -R "$PHP_USER" /var/www/html/wp-content
    exit_if_error $? "$ERROR_CHOWN_WPCONTENT"

    if [[ "$cache_type" == "fastcgi-cache" || "$cache_type" == "w3-total-cache" ]]; then
        if ! grep -q "fastcgi_cache_path" "$NGINX_MAIN_CONF"; then
            sedi "/http {/a\\
fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;" "$NGINX_MAIN_CONF"
            exit_if_error $? "$ERROR_ADD_FASTCGI_PATH"
            print_msg success "$SUCCESS_FASTCGI_PATH_ADDED"
        fi

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- option update rt_wp_nginx_helper_options '{"enable_purge":true}' --format=json
        exit_if_error $? "$ERROR_UPDATE_NGINX_HELPER"
    fi

    if [[ "$cache_type" == "fastcgi-cache" ]]; then
        redis_start
        if ! grep -q "WP_REDIS_HOST" "$wp_config_file"; then
            sedi "/<?php/a\\
define('WP_REDIS_HOST', '${REDIS_CONTAINER}');\\
define('WP_REDIS_PORT', 6379);\\
define('WP_REDIS_DATABASE', 0);" "$wp_config_file"
        fi

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- plugin install redis-cache --activate
        exit_if_error $? "$ERROR_REDIS_PLUGIN_INSTALL"

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- redis update-dropin
        exit_if_error $? "$ERROR_REDIS_UPDATE_DROPIN"

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- option update redis-cache
        exit_if_error $? "$ERROR_REDIS_UPDATE_OPTIONS"

        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- redis enable
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
