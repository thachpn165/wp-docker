#!/bin/bash

# 🛠️ Configure wp-config.php
wp_set_wpconfig() {
    local container_php="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    local container_db="$5"

    echo -e "${YELLOW}⚙️ Configuring wp-config.php in container $container_php...${NC}"

    docker exec -i "$container_php" sh -c "
        cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php && \
        sed -i 's/database_name_here/$db_name/' /var/www/html/wp-config.php && \
        sed -i 's/username_here/$db_user/' /var/www/html/wp-config.php && \
        sed -i 's/password_here/$db_pass/' /var/www/html/wp-config.php && \
        sed -i 's/localhost/$container_db/' /var/www/html/wp-config.php && \
        cat <<'EOF' | tee -a /var/www/html/wp-config.php

// 🚀 Enhance SSL security for WordPress
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    \$_SERVER['HTTPS'] = 'on';
}
EOF
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${CHECKMARK} wp-config.php has been configured successfully.${NC}"
    else
        echo -e "${RED}${CROSSMARK} Error configuring wp-config.php.${NC}"
        exit 1
    fi
}

# 🚀 Install WordPress
wp_install() {
    local container="$1"
    local site_url="$2"
    local title="$3"
    local admin_user="$4"
    local admin_pass="$5"
    local admin_email="$6"

    echo "🚀 Installing WordPress..."
    docker exec -e WP_CLI_CACHE_DIR=/tmp/wp-cli-cache -i "$container" sh -c "
        wp core install --url='$site_url' --title='$title' --admin_user='$admin_user' \
        --admin_password='$admin_pass' --admin_email='$admin_email' --skip-email --path=/var/www/html --allow-root
    "
    echo "${CHECKMARK} WordPress has been installed."
}

# 📌 **Set up Permalinks**
wp_set_permalinks() {
    local container="$1"
    local site_url="$2"

    echo -e "${YELLOW}🔗 Setting up WordPress permalinks...${NC}"
    docker exec -e WP_CLI_CACHE_DIR=/tmp/wp-cli-cache -u "$PHP_USER" -i "$container" sh -c "wp option update permalink_structure '/%postname%/' --path=/var/www/html"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${CHECKMARK} Permalinks have been set up successfully.${NC}"
    else
        echo -e "${RED}${CROSSMARK} Error setting up permalinks.${NC}"
        exit 1
    fi
}

# 📌 **Install and activate security plugin**
wp_plugin_install_security_plugin() {
    local container="$1"

    echo -e "${YELLOW}🔒 Installing WordPress security plugin...${NC}"
    docker exec -e WP_CLI_CACHE_DIR=/tmp/wp-cli-cache -u "$PHP_USER" -i "$container" sh -c "wp plugin install limit-login-attempts-reloaded --activate --path=/var/www/html"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${CHECKMARK} Security plugin has been installed and activated.${NC}"
    else
        echo -e "${RED}${CROSSMARK} Error installing security plugin.${NC}"
        exit 1
    fi
}

# 📌 **Install and activate Performance Lab plugin**
wp_plugin_install_performance_lab() {
    local container="$1"

    echo -e "${YELLOW}🔧 Installing and activating Performance Lab plugin...${NC}"
    docker exec -e WP_CLI_CACHE_DIR=/tmp/wp-cli-cache -u "$PHP_USER" -i "$container" sh -c "wp plugin install performance-lab --activate --path=/var/www/html"

    echo -e "${GREEN}${CHECKMARK} Performance Lab plugin has been installed and WebP Uploads module has been activated.${NC}"
}

# Check and update WP-CLI
check_and_update_wp_cli() {
    local wp_cli_path="shared/bin/wp"
    local current_version

    mkdir -p "$(dirname "$wp_cli_path")"

    if [ -f "$wp_cli_path" ]; then
        current_version=$("$wp_cli_path" --version 2>/dev/null | awk '{print $2}')
        echo -e "${GREEN}🔍 Current WP-CLI: v$current_version${NC}"
        echo -e "${YELLOW}🔄 Checking & updating WP-CLI...${NC}"
    else
        echo -e "${YELLOW}${WARNING} WP-CLI does not exist. Downloading latest version...${NC}"
    fi

    curl -sSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o "$wp_cli_path"
    chmod +x "$wp_cli_path"

    new_version=$("$wp_cli_path" --version 2>/dev/null | awk '{print $2}')
    echo -e "${GREEN}${CHECKMARK} WP-CLI is now version: v$new_version${NC}"
}
