#!/bin/bash
wordpress_cache_setup_logic() {
    local site_name="$1"
    local cache_type="$2"
    local site_dir="$SITES_DIR/$site_name"
    local wp_config_file="$site_dir/wordpress/wp-config.php"
    local nginx_conf_file="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"
    local PHP_CONTAINER="$site_name-php"

    # Ensure the site directory exists
    if [ ! -d "$site_dir" ]; then
        echo -e "${RED}❌ Website directory does not exist: $site_dir${NC}"
        return 1
    fi

    # Deactivate existing cache plugins
    local cache_plugins=("wp-super-cache" "nginx-helper" "w3-total-cache" "redis-cache" "wp-fastest-cache")
    local active_plugins
    active_plugins=$(docker_exec_php "wp plugin list --status=active --field=name --path=$PHP_CONTAINER_WP_PATH")

for plugin in "${cache_plugins[@]}"; do
    # Check if the plugin is active
    if echo "$active_plugins" | grep -q "$plugin"; then
        echo -e "${YELLOW}⚠️ Plugin $plugin is active, it will be deactivated.${NC}"
        # Only deactivate if the plugin is active
        if docker_exec_php "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH"; then
            echo -e "${GREEN}✅ Plugin $plugin deactivated successfully.${NC}"
        else
            echo -e "${RED}❌ An error occurred while deactivating the plugin: $plugin${NC}"
        fi
    else
        # If the plugin is not active, skip deactivation
        echo -e "Plugin $plugin is not active, skipping deactivation."
    fi
done

    # Handle "no-cache" option
    if [[ "$cache_type" == "no-cache" ]]; then
        echo -e "${YELLOW}🧹 Removing cache plugins and disabling WP_CACHE...${NC}"
        for plugin in "${cache_plugins[@]}"; do
            # Check if the plugin is active
            if echo "$active_plugins" | grep -q "$plugin"; then
                echo -e "${YELLOW}⚠️ Plugin $plugin is active, it will be deactivated and deleted.${NC}"

                # Deactivate the plugin if it is active
                if docker_exec_php "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH"; then
                    echo -e "${GREEN}✅ Plugin $plugin deactivated successfully.${NC}"
                else
                    echo -e "${RED}❌ An error occurred while deactivating the plugin: $plugin${NC}"
                    return 1
                fi

                # Delete the plugin after deactivating
                if docker_exec_php "wp plugin delete $plugin --path=$PHP_CONTAINER_WP_PATH"; then
                    echo -e "${GREEN}✅ Plugin $plugin deleted successfully.${NC}"
                else
                    echo -e "${RED}❌ An error occurred while deleting the plugin: $plugin${NC}"
                    return 1
                fi
            else
                echo -e "${GREEN}Plugin $plugin is not active, skipping deactivation and deletion.${NC}"
            fi
        done
        sedi "/define('WP_CACHE', true);/d" "$wp_config_file"
        exit_if_error $? "❌ An error occurred while removing WP_CACHE from wp-config.php"
        if grep -q "include /etc/nginx/cache/" "$nginx_conf_file"; then
            sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/no-cache.conf;|" "$nginx_conf_file"
            exit_if_error $? "❌ An error occurred while updating NGINX configuration for no-cache."
        fi
        nginx_reload
        exit_if_error $? "❌ An error occurred while reloading NGINX."
        echo -e "${GREEN}✅ Cache has been disabled and NGINX reloaded.${NC}"
        return 0
    fi

    # Configure NGINX to include the proper cache configuration
    if grep -q "include /etc/nginx/cache/" "$nginx_conf_file"; then
        sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/${cache_type}.conf;|" "$nginx_conf_file"
        exit_if_error $? "❌ An error occurred while updating NGINX configuration for cache type: $cache_type"
        echo -e "${GREEN}✅ NGINX configuration updated for cache type: $cache_type${NC}"
    else
        echo -e "${RED}❌ Could not find cache include line in NGINX configuration!${NC}"
        return 1
    fi

    # Install and activate the chosen cache plugin
    local plugin_slug
    case "$cache_type" in
        "wp-super-cache") plugin_slug="wp-super-cache" ;;
        "fastcgi-cache") plugin_slug="nginx-helper" ;;
        "w3-total-cache") plugin_slug="w3-total-cache" ;;
        "wp-fastest-cache") plugin_slug="wp-fastest-cache" ;;
    esac

    docker_exec_php "wp plugin install $plugin_slug --activate --path=$PHP_CONTAINER_WP_PATH"
    docker exec -u root -i "$PHP_CONTAINER" chown -R $PHP_USER /var/www/html/wp-content
    exit_if_error $? "❌ An error occurred while changing ownership of wp-content directory."

    # Handle FastCGI cache and Redis options
    if [[ "$cache_type" == "fastcgi-cache" || "$cache_type" == "w3-total-cache" ]]; then
        # Kiểm tra nếu cấu hình fastcgi_cache_path chưa có trong nginx.conf
        if ! grep -q "fastcgi_cache_path" "$NGINX_MAIN_CONF"; then
            # Thêm cấu hình fastcgi_cache_path vào trong nginx.conf trực tiếp trên host
            sedi "/http {/a\\
            fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;" "$NGINX_MAIN_CONF"
            exit_if_error $? "❌ An error occurred while adding fastcgi_cache_path to NGINX main configuration."
            echo -e "${GREEN}✅ FastCGI Cache configuration added to NGINX.${NC}"
        fi

        # Cập nhật các tùy chọn cho Nginx Helper Plugin
        docker_exec_php "wp option update rt_wp_nginx_helper_options '{\"enable_purge\":true}' --format=json --path=$PHP_CONTAINER_WP_PATH"
    fi

    if [[ "$cache_type" == "fastcgi-cache" ]]; then
        if ! grep -q "WP_REDIS_HOST" "$wp_config_file"; then
            sedi "/<?php/a\\
            define('WP_REDIS_HOST', 'redis-cache');\\
            define('WP_REDIS_PORT', 6379);\\
            define('WP_REDIS_DATABASE', 0);" "$wp_config_file"
        fi
        docker_exec_php "wp plugin install redis-cache --activate --path=$PHP_CONTAINER_WP_PATH"
        docker_exec_php "wp redis update-dropin --path=$PHP_CONTAINER_WP_PATH"
        docker_exec_php "wp redis enable --path=$PHP_CONTAINER_WP_PATH"
    fi

    # Reload NGINX to apply new cache settings
    nginx_reload
    exit_if_error $? "❌ An error occurred while reloading NGINX."

    echo -e "${GREEN}✅ NGINX reloaded to apply new cache settings.${NC}"
}
