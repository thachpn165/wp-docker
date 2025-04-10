#!/bin/bash
wordpress_reset_wp_database_logic() {
    domain="$1"  # site_name sẽ được truyền từ file menu hoặc CLI
    SITE_DIR="$SITES_DIR/$domain"
    ENV_FILE="$SITE_DIR/.env"

    # **Lấy thông tin database từ .env**
    if ! json_key_exists ".site[\"$domain\"]"; then
        print_msg error "$ERROR_WEBSITE_NOT_EXIST: $domain"
        return 1
    fi

    # Fetch database credentials from .config.json
    db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
    db_user=$(json_get_site_value "$domain" "MYSQL_USER")
    db_pass=$(json_get_site_value "$domain" "MYSQL_PASSWORD")

    # **Thực hiện reset database bằng hàm utils**
    db_reset_database "$domain" "$db_user" "$db_pass" "$db_name"
}
