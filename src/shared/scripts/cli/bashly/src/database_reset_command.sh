safe_source "$CLI_DIR/database_actions.sh"

database_cli_reset --domain="${args[domain]}" || exit 1