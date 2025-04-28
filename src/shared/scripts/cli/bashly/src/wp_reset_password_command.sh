safe_source "$CLI_DIR/wordpress_reset_admin_passwd.sh"

user_id="${args[user_id]}"
domain="${args[domain]}"
if [[ -z "$user_id" ]]; then
    print_msg info "$INFO_WORDPRESS_LIST_ADMINS"
    wordpress_wp_cli_logic "$domain" user list --role=administrator --fields=ID,user_login --format=table
    echo ""
    user_id=$(get_input_or_test_value "$PROMPT_WORDPRESS_ENTER_USER_ID" "${TEST_USER_ID:-0}")
fi

wordpress_cli_reset_admin_passwd --domain="$domain" --user_id="$user_id" || exit 1
