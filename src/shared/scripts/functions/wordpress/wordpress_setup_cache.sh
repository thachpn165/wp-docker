#!/bin/bash
# ==================================================
# File: wordpress_setup_cache.sh
# Description: Functions to manage caching configurations for WordPress websites, including:
#              - Prompting the user to select and configure a cache plugin.
#              - Setting up or removing caching configurations for a WordPress site.
# Functions:
#   - wordpress_prompt_cache_setup: Prompt user to select and configure a cache plugin.
#       Parameters: None.
#   - wordpress_cache_setup_logic: Set up or remove caching configuration for a WordPress site.
#       Parameters:
#           $1 - domain: Domain name of the website.
#           $2 - cache_type: Cache type to configure (e.g., wp-super-cache, fastcgi-cache, w3-total-cache, no-cache).
# ==================================================

wordpress_prompt_cache_setup() {
    # Prompt user to select and configure a cache plugin.
    # Parameters: None.

    local domain cache_type plugin_slug
    safe_source "$CLI_DIR/wordpress_cache_setup.sh"

    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_NO_WEBSITE_SELECTED"
        exit 1
    fi

    current_cache=$(json_get_site_value "$domain" "cache")

    # Load cache type list from JSON
    print_msg title "$LABEL_MENU_MAIN_WORDPRESS_CACHE"

    mapfile -t cache_types < <(jq -r 'keys[] | select(. != "no-cache")' <<<"$WP_CACHE_PLUGIN_JSON" | sort)
    cache_types+=("no-cache")

    for i in "${!cache_types[@]}"; do
        local type="${cache_types[$i]}"
        local label
        label=$(jq -r --arg type "$type" '.[$type].name' <<<"$WP_CACHE_PLUGIN_JSON")

        if [[ "$type" == "$current_cache" ]]; then
            label="$label ${YELLOW}($LABEL_CURRENT_SELECTED)${NC}"
        fi

        print_msg info "  ${GREEN}[$((i + 1))]${NC} $label"
    done

    # Prompt user input
    local cache_type_index
    cache_type_index=$(get_input_or_test_value "$PROMPT_WORDPRESS_CHOOSE_CACHE")

    if ! [[ "$cache_type_index" =~ ^[0-9]+$ ]] || ((cache_type_index < 1 || cache_type_index > ${#cache_types[@]})); then
        print_msg error "$ERROR_SELECT_OPTION_INVALID"
        exit 1
    fi

    cache_type="${cache_types[$((cache_type_index - 1))]}"
    plugin_slug=$(jq -r --arg type "$cache_type" '.[$type].plugin' <<<"$WP_CACHE_PLUGIN_JSON")

    print_msg success "$SUCCESS_WORDPRESS_CHOOSE_CACHE: $cache_type"
    wordpress_cli_cache_setup --domain="$domain" --cache_type="$cache_type"
}

wordpress_cache_setup_logic() {
    # Set up or remove caching configuration for a WordPress site.
    # Parameters:
    #   $1 - domain: Domain name of the website.
    #   $2 - cache_type: Cache type to configure (e.g., wp-super-cache, fastcgi-cache, w3-total-cache, no-cache).

    local domain="$1"
    local cache_type="$2"
    local site_dir="$SITES_DIR/$domain"
    local wp_config_file="$site_dir/wordpress/wp-config.php"
    local nginx_conf_file="$NGINX_PROXY_DIR/conf.d/${domain}.conf"
    local php_container
    php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")

    _is_valid_domain "$domain" || return 1

    if [[ ! -d "$site_dir" ]]; then
        print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$site_dir")"
        return 1
    fi

    if ! jq -e --arg ct "$cache_type" 'has($ct)' <<<"$WP_CACHE_PLUGIN_JSON" >/dev/null; then
        print_and_debug error "$(printf "$ERROR_INVALID_CACHE_TYPE" "$cache_type")"
        return 1
    fi

    local plugin_slug
    plugin_slug=$(jq -r --arg type "$cache_type" '.[$type].plugin' <<<"$WP_CACHE_PLUGIN_JSON")

    local cache_plugins
    mapfile -t cache_plugins < <(jq -r '.[] | .plugin' <<<"$WP_CACHE_PLUGIN_JSON" | grep -v '^$')
    cache_plugins+=("redis-cache")

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

    wordpress_wp_cli_logic "$domain" plugin install "$plugin_slug" --activate
    exit_if_error $? "$(printf "$ERROR_PLUGIN_INSTALL" "$plugin_slug")"

    docker exec -u root -i "$php_container" chown -R "$PHP_USER" /var/www/html/wp-content
    exit_if_error $? "$ERROR_CHOWN_WPCONTENT"

    if [[ "$cache_type" == "fastcgi-cache" || "$cache_type" == "w3-total-cache" ]]; then
        if ! grep -q "fastcgi_cache_path" "$NGINX_MAIN_CONF"; then
            sedi "/http {/a\\
fastcgi_cache_path /usr/local/openresty/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;" "$NGINX_MAIN_CONF"
            exit_if_error $? "$ERROR_ADD_FASTCGI_PATH"
            print_msg success "$SUCCESS_FASTCGI_PATH_ADDED"
        fi
    fi

    if [[ "$cache_type" == "fastcgi-cache" ]]; then
        core_redis_start
        if ! grep -q "WP_REDIS_HOST" "$wp_config_file"; then
            sedi "/<?php/a\\
define('WP_REDIS_HOST', '${REDIS_CONTAINER}');\\
define('WP_REDIS_PORT', 6379);\\
define('WP_REDIS_DATABASE', 0); \\
define('RT_WP_NGINX_HELPER_CACHE_PATH','/var/cache/nginx');" "$wp_config_file"
            exit_if_error $? "$ERROR_ADD_REDIS_DEFINES"
            print_msg success "$SUCCESS_REDIS_DEFINES_ADDED"
        fi

        wordpress_wp_cli_logic "$domain" plugin install redis-cache --activate
        exit_if_error $? "$ERROR_REDIS_PLUGIN_INSTALL"

        wordpress_wp_cli_logic "$domain" redis update-dropin
        exit_if_error $? "$ERROR_REDIS_UPDATE_DROPIN"

        wordpress_wp_cli_logic "$domain" redis enable
        exit_if_error $? "$ERROR_REDIS_ENABLE"
    fi

    nginx_reload
    exit_if_error $? "$ERROR_NGINX_RELOAD"
    print_msg success "$SUCCESS_NGINX_RELOADED"
    json_set_site_value "$domain" "cache" "$cache_type"
    case "$cache_type" in
    fastcgi-cache)
        print_msg important "$TIP_CACHE_FASTCGI_CACHE"
        ;;
    wp-super-cache)
        print_msg important "$TIP_CACHE_WP_SUPER_CACHE"
        ;;
    w3-total-cache)
        print_msg important "$TIP_CACHE_W3_TOTAL_CACHE"
        ;;
    wp-fastest-cache)
        print_msg important "$TIP_CACHE_WP_FASTEST_CACHE"
        ;;
    esac
}
