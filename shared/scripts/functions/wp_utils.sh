#!/bin/bash

# 📌 Kiểm tra xem WP-CLI đã được cài đặt trong container hay chưa
is_wp_cli_installed() {
    local container="$1"
    docker exec -i "$container" sh -c "command -v wp" &> /dev/null
}

# 📥 Cài đặt WP-CLI nếu chưa có
install_wp_cli() {
    local container="$1"
    echo -e "${YELLOW}📥 Kiểm tra WP-CLI trong container: $container...${NC}"
    
    if ! is_wp_cli_installed "$container"; then
        echo -e "${YELLOW}🚀 Đang cài đặt WP-CLI trong container: $container...${NC}"
        docker exec -i "$container" sh -c "
            curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
            chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
        "
        echo -e "${GREEN}✅ WP-CLI đã được cài đặt thành công.${NC}"
    else
        echo -e "${GREEN}✅ WP-CLI đã được cài đặt trước đó.${NC}"
    fi
}

# 🔄 Kiểm tra và cài đặt WP-CLI nếu cần
check_and_install_wp_cli() {
    local container="$1"
    if ! is_wp_cli_installed "$container"; then
        install_wp_cli "$container"
    fi
}

# 🏗️ Kiểm tra xem WordPress đã được cài đặt chưa
is_wordpress_installed() {
    local container="$1"
    docker exec -i "$container" sh -c "wp core is-installed --path=/var/www/html --allow-root" &> /dev/null
}

# 🛠️ Cấu hình wp-config.php
wp_set_wpconfig() {
    local container_php="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    local container_db="$5"

    echo -e "${YELLOW}⚙️ Đang cấu hình wp-config.php trong container $container_php...${NC}"

    docker exec -i "$container_php" sh -c "
        cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php && \
        sed -i 's/database_name_here/$db_name/' /var/www/html/wp-config.php && \
        sed -i 's/username_here/$db_user/' /var/www/html/wp-config.php && \
        sed -i 's/password_here/$db_pass/' /var/www/html/wp-config.php && \
        sed -i 's/localhost/$container_db/' /var/www/html/wp-config.php && \
        cat <<'EOF' | tee -a /var/www/html/wp-config.php

// 🚀 Tăng cường bảo mật SSL cho WordPress
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    \$_SERVER['HTTPS'] = 'on';
}
EOF
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ wp-config.php đã được cấu hình thành công.${NC}"
    else
        echo -e "${RED}❌ Lỗi khi cấu hình wp-config.php.${NC}"
        exit 1
    fi
}

# 🚀 Cài đặt WordPress
wp_install() {
    local container="$1"
    local site_url="$2"
    local title="$3"
    local admin_user="$4"
    local admin_pass="$5"
    local admin_email="$6"

    echo "🚀 Đang cài đặt WordPress..."
    docker exec -i "$container" sh -c "
        wp core install --url='$site_url' --title='$title' --admin_user='$admin_user' \
        --admin_password='$admin_pass' --admin_email='$admin_email' --path=/var/www/html --allow-root
    "
    echo "✅ WordPress đã được cài đặt."
}

# 📋 Lấy giá trị biến môi trường từ tệp .env
fetch_env_variable() {
    local env_file="$1"
    local var_name="$2"
    if [ -f "$env_file" ]; then
        grep -E "^${var_name}=" "$env_file" | cut -d'=' -f2 | tr -d '\r'
    else
        echo -e "${RED}❌ Lỗi: Tệp .env không tồn tại: $env_file${NC}" >&2
        return 1
    fi
}

# 📌 **Thiết lập Permalinks**
wp_set_permalinks() {
    local container="$1"
    local site_url="$2"

    echo -e "${YELLOW}🔗 Đang thiết lập permalinks cho WordPress...${NC}"
    docker exec -i "$container" sh -c "wp option update permalink_structure '/%postname%/' --path=/var/www/html --allow-root"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Permalinks đã được thiết lập thành công.${NC}"
    else
        echo -e "${RED}❌ Lỗi khi thiết lập permalinks.${NC}"
        exit 1
    fi
}

# 📌 **Cài đặt và kích hoạt plugin bảo mật**
wp_plugin_install_security_plugin() {
    local container="$1"

    echo -e "${YELLOW}🔒 Đang cài đặt plugin bảo mật WordPress...${NC}"
    docker exec -i "$container" sh -c "wp plugin install limit-login-attempts-reloaded --activate --path=/var/www/html --allow-root"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Plugin bảo mật đã được cài đặt và kích hoạt.${NC}"
    else
        echo -e "${RED}❌ Lỗi khi cài đặt plugin bảo mật.${NC}"
        exit 1
    fi
}

# 📌 **Cài đặt và kích hoạt plugin Performance Lab**
wp_plugin_install_performance_lab() {
    local container="$1"
    
    echo -e "${YELLOW}🔧 Đang cài đặt và kích hoạt plugin Performance Lab...${NC}"
     docker exec -i "$container" sh -c " wp plugin install performance-lab --activate --path=/var/www/html --allow-root"
    
    echo -e "${YELLOW}⚙️ Đang bật module WebP Uploads...${NC}"
     docker exec -i "$container" sh -c " wp option update performance_lab_modules --add='{"webp_uploads":true}' --path=/var/www/html --allow-root"

    
    echo -e "${GREEN}✅ Plugin Performance Lab đã được cài đặt và module WebP Uploads đã được kích hoạt.${NC}"
}