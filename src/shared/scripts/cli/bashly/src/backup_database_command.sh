safe_source "$CLI_DIR/database_actions.sh"

database_cli_export --domain="${args[domain]}" --save_location="${args[save_location]}"