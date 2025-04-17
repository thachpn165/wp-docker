#!/bin/bash

wordpress_prompt_reset_admin_passwd() {
    local domain 
    # 📋 Chọn website
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_NO_WEBSITE_SELECTED"
        exit 1
    fi

    # 📋 Hiển thị danh sách admin
    print_msg info "$INFO_WORDPRESS_LIST_ADMINS"
    bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- user list --role=administrator --fields=ID,user_login --format=table
    echo ""

    # 🔐 Nhập user ID
    user_id=$(get_input_or_test_value "$PROMPT_WORDPRESS_ENTER_USER_ID" "${TEST_USER_ID:-0}")
    if [[ -z "$user_id" ]]; then
        print_msg error "$ERROR_INPUT_REQUIRED"
        exit 1
    fi

    # ▶️ Gọi CLI thực hiện reset
    wordpress_cli_reset_admin_passwd --domain="$domain" --user_id="$user_id"
}
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
}
