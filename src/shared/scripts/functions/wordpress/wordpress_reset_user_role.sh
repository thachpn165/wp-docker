# =====================================
# reset_user_role_logic: Reset all WordPress user roles to default for a given site
# Parameters:
#   $1 - domain (site name)
# Behavior:
#   - Executes WP-CLI command to reset all roles
#   - Displays success or error message
# =====================================
reset_user_role_logic() {
    local domain="$1"  # site_name passed from CLI or menu

    print_msg step "$STEP_WORDPRESS_RESET_ROLE"
    wordpress_wp_cli_logic "$domain" "role reset --all"
    exit_if_error "$?" "$ERROR_WORDPRESS_RESET_ROLE"
    print_msg success "$(printf "$SUCCESS_WORDPRESS_RESET_ROLE" "$domain")"
}