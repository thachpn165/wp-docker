safe_source "$CLI_DIR/wordpress_auto_update_plugin.sh"

wordpress_cli_auto_update_plugin --domain="${args[domain]}" --action="${args[action]}" || exit 1