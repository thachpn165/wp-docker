safe_source "$CLI_DIR/wordpress_migration.sh"

wordpress_cli_migration --domain="${args[domain]}" || exit 1