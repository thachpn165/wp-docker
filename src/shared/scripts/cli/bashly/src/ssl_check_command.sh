safe_source "$CLI_DIR/ssl_check_status.sh"

ssl_cli_check_status --domain="${args[domain]}" || exit 1