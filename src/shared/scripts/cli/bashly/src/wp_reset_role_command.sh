safe_source "$CLI_DIR/wordpress_reset_user_role.sh"

wordpress_cli_reset_roles --domain="${args[domain]}" || exit 1