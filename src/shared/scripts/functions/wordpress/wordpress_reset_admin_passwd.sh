#!/bin/bash
reset_admin_password_logic() {
    local domain="$1"
    local user_id="$2"

    if [[ -z "$domain" || -z "$user_id" ]]; then
        echo -e "${RED}${CROSSMARK} Thiếu tham số. Cần truyền domain và user_id.${NC}"
        exit 1
    fi

    SITE_DIR="$SITES_DIR/$domain"
    PHP_CONTAINER="$domain-php"

    # Tạo mật khẩu ngẫu nhiên 18 ký tự không có ký tự đặc biệt
    new_password=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 18)

    # Cập nhật mật khẩu
    #docker exec "$PHP_CONTAINER" wp user update "$user_id" --user_pass="$new_password" --path=/var/www/html
    bash $CLI_DIR/wordpress_wp_cli.sh --domain="${domain}" -- user update "$user_id" --user_pass="$new_password"
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSSMARK} Không thể cập nhật mật khẩu cho tài khoản ID $user_id.${NC}"
        exit 1
    fi
    echo -e "${GREEN}${CHECKMARK} Mật khẩu mới của tài khoản ID $user_id: $new_password${NC}"
    echo -e "${YELLOW}${WARNING} Hãy lưu mật khẩu này ở nơi an toàn!${NC}"
}
