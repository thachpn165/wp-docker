reset_user_role_logic() {


    # Lấy tên website từ tham số site_name
    domain="$1"  # site_name sẽ được truyền từ file menu hoặc CLI

    SITE_DIR="$SITES_DIR/$domain"
    PHP_CONTAINER="$domain-php"

    # **Chạy lệnh WP CLI để reset lại quyền**
    print_msg step "$STEP_WORDPRESS_RESET_ROLE"
    bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- role reset --all
    exit_if_error "$?" "$ERROR_WORDPRESS_RESET_ROLE"
    print_msg success "$(printf "$SUCCESS_WORDPRESS_RESET_ROLE" "$domain")"
}
