safe_source "$CLI_DIR/wordpress_protect_wp_login.sh"

wordpress_cli_protect_wplogin --domain="${args[domain]}" --action="${args[action]}" || exit 1