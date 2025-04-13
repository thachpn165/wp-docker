#!/bin/bash

# =====================================
# reset_admin_password_logic: Reset WordPress admin password for a given user ID
# Parameters:
#   $1 - domain (site name)
#   $2 - user_id (WordPress user ID or login)
# Behavior:
#   - Generates a random 18-character alphanumeric password
#   - Updates password via WP-CLI
#   - Prints new password to user
# =====================================
reset_admin_password_logic() {
    local domain="$1"
    local user_id="$2"

    if [[ -z "$domain" || -z "$user_id" ]]; then
        print_msg error "$ERROR_MISSING_PARAM: domain or user_id"
        exit 1
    fi

    # 🔐 Generate a random 18-character alphanumeric password (no special characters)
    new_password=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 18)

    # 🔄 Update password via WP-CLI
    wordpress_wp_cli_logic "$domain" "user update $user_id --user_pass=$new_password"
    if [[ $? -ne 0 ]]; then
        print_and_debug error "$ERROR_WORDPRESS_RESET_ADMIN_PASSWD $user_id."
        exit 1
    fi

    print_msg success "$SUCCESS_WORDPRESS_RESET_ADMIN_PASSWD $user_id: ${BLUE}$new_password${NC}"
    print_msg warning "$WARNING_EDITOR_CANCELLED"
}