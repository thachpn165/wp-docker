safe_source "$FUNCTIONS_DIR/wordpress/wordpress_wp_cli.sh"



wordpress_wp_cli_logic "${args[domain]}" "${args[command]}" || exit 1

