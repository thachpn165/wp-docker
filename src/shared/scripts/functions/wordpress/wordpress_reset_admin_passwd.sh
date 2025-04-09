#!/bin/bash

reset_admin_password_logic() {
    local domain="$1"
    local user_id="$2"

    if [[ -z "$domain" || -z "$user_id" ]]; then
        print_msg error "$ERROR_MISSING_PARAM: domain or user_id"
        exit 1
    fi

    SITE_DIR="$SITES_DIR/$domain"
    PHP_CONTAINER=$(json_get_site_value "$domain" "CONTAINER_PHP")

    # 🔐 Tạo mật khẩu ngẫu nhiên 18 ký tự không có ký tự đặc biệt
    new_password=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 18)

    # 🔄 Cập nhật mật khẩu qua WP-CLI
    wordpress_wp_cli_logic "$domain" "user update $user_id --user_pass=$new_password"
    if [[ $? -ne 0 ]]; then
        print_and_debug error "$ERROR_WORDPRESS_RESET_ADMIN_PASSWD $user_id."
        exit 1
    fi

    print_msg success "$SUCCESS_WORDPRESS_RESET_ADMIN_PASSWD $user_id: ${BLUE}$new_password${NC}"
    print_msg warning "$WARNING_EDITOR_CANCELLED"
}
