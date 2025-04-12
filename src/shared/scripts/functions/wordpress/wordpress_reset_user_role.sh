reset_user_role_logic() {

    # Lấy tên website từ tham số site_name
    domain="$1"  # site_name sẽ được truyền từ file menu hoặc CLI

    # **Chạy lệnh WP CLI để reset lại quyền**
    print_msg step "$STEP_WORDPRESS_RESET_ROLE"
    wordpress_wp_cli_logic "$domain" "role reset --all"
    exit_if_error "$?" "$ERROR_WORDPRESS_RESET_ROLE"
    print_msg success "$(printf "$SUCCESS_WORDPRESS_RESET_ROLE" "$domain")"
}
