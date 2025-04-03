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

    # Ensure the site directory exists
    if [ ! -d "$site_dir" ]; then
        echo -e "${RED}${CROSSMARK} Website directory does not exist: $site_dir${NC}"
        return 1
    fi

    # Deactivate existing cache plugins
    local cache_plugins=("wp-super-cache" "nginx-helper" "w3-total-cache" "redis-cache" "wp-fastest-cache")
    local active_plugins
    active_plugins=$(docker_exec_php "wp plugin list --status=active --field=name --path=$PHP_CONTAINER_WP_PATH")

    for plugin in "${cache_plugins[@]}"; do
        # Check if the plugin is active
        if echo "$active_plugins" | grep -q "$plugin"; then
            echo -e "${YELLOW}${WARNING} Plugin $plugin is active, it will be deactivated.${NC}"
            # Only deactivate if the plugin is active
            if docker_exec_php "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH"; then
                echo -e "${GREEN}${CHECKMARK} Plugin $plugin deactivated successfully.${NC}"
            else
                echo -e "${RED}${CROSSMARK} An error occurred while deactivating the plugin: $plugin${NC}"
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
                echo -e "${YELLOW}${WARNING} Plugin $plugin is active, deactivating and deleting...${NC}"

                # Deactivate and delete the plugin in one block
                if docker_exec_php "wp plugin deactivate $plugin --path=$PHP_CONTAINER_WP_PATH" && \
                   docker_exec_php "wp plugin delete $plugin --path=$PHP_CONTAINER_WP_PATH"; then
                    echo -e "${GREEN}${CHECKMARK} Plugin $plugin deactivated and deleted successfully.${NC}"
                else
                    echo -e "${RED}${CROSSMARK} Error occurred while deactivating or deleting plugin: $plugin${NC}"
                    return 1
                fi
            else
                echo -e "${GREEN}Plugin $plugin is not active, skipping deactivation and deletion.${NC}"
            fi
        done

        # Remove WP_CACHE definition from wp-config.php
        if ! sedi "/define('WP_CACHE', true);/d" "$wp_config_file"; then
            echo -e "${RED}${CROSSMARK} Error occurred while removing WP_CACHE from wp-config.php.${NC}"
            return 1
        fi

        # Update NGINX configuration for no-cache
        if grep -q "include /etc/nginx/cache/" "$nginx_conf_file"; then
            if ! sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/no-cache.conf;|" "$nginx_conf_file"; then
                echo -e "${RED}${CROSSMARK} Error occurred while updating NGINX configuration for no-cache.${NC}"
                return 1
            fi
        fi

        # Reload NGINX
        if ! nginx_reload; then
            echo -e "${RED}${CROSSMARK} Error occurred while reloading NGINX.${NC}"
            return 1
        fi

        echo -e "${GREEN}${CHECKMARK} Cache has been disabled and NGINX reloaded.${NC}"
        return 0
    fi

    # Configure NGINX to include the proper cache configuration
    if grep -q "include /etc/nginx/cache/" "$nginx_conf_file"; then
        sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/${cache_type}.conf;|" "$nginx_conf_file"
        exit_if_error $? "${CROSSMARK} An error occurred while updating NGINX configuration for cache type: $cache_type"
        echo -e "${GREEN}${CHECKMARK} NGINX configuration updated for cache type: $cache_type${NC}"
    else
        echo -e "${RED}${CROSSMARK} Could not find cache include line in NGINX configuration!${NC}"
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
    exit_if_error $? "${CROSSMARK} An error occurred while changing ownership of wp-content directory."

    # Handle FastCGI cache and Redis options
    if [[ "$cache_type" == "fastcgi-cache" || "$cache_type" == "w3-total-cache" ]]; then
        # Check if fastcgi_cache_path is configured in nginx.conf
        if ! grep -q "fastcgi_cache_path" "$NGINX_MAIN_CONF"; then
            # Add fastcgi_cache_path configuration to nginx.conf directly on host
            sedi "/http {/a\\
            fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;" "$NGINX_MAIN_CONF"
            exit_if_error $? "${CROSSMARK} An error occurred while adding fastcgi_cache_path to NGINX main configuration."
            echo -e "${GREEN}${CHECKMARK} FastCGI Cache configuration added to NGINX.${NC}"
        fi

        # Update options for Nginx Helper Plugin
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
    exit_if_error $? "${CROSSMARK} An error occurred while reloading NGINX."
    echo -e "${GREEN}${CHECKMARK} NGINX reloaded to apply new cache settings.${NC}"

    # Provide the instructions based on cache type
    if [[ "$cache_type" == "wp-super-cache" ]]; then
        echo -e "${YELLOW}${WARNING} Instructions to complete WP Super Cache setup:${NC}"
        echo -e "  1️⃣ Go to WordPress Admin -> Settings -> WP Super Cache."
        echo -e "  2️⃣ Enable 'Caching On' to activate caching."
        echo -e "  3️⃣ Select 'Expert' in 'Cache Delivery Method'."
        echo -e "  4️⃣ Save the settings and verify cache is working."
    fi

    if [[ "$cache_type" == "w3-total-cache" ]]; then
        echo -e "${YELLOW}${WARNING} Instructions to complete W3 Total Cache setup:${NC}"
        echo -e "  1️⃣ Go to WordPress Admin -> Performance -> General Settings."
        echo -e "  2️⃣ Enable all relevant caching options (Page Cache, Object Cache, Database Cache)."
        echo -e "  3️⃣ Save the settings and verify cache is working."
    fi

    if [[ "$cache_type" == "wp-fastest-cache" ]]; then
        echo -e "${YELLOW}${WARNING} Instructions to complete WP Fastest Cache setup:${NC}"
        echo -e "  1️⃣ Go to WordPress Admin -> WP Fastest Cache."
        echo -e "  2️⃣ Enable the 'Enable Cache' option."
        echo -e "  3️⃣ Choose the appropriate 'Cache System'."
        echo -e "  4️⃣ Save the settings and verify cache is working."
    fi
}