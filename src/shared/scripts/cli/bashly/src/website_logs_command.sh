safe_source "$CLI_DIR/website_manage.sh"

website_cli_logs --domain="${args[domain]}" --log_type="${args[log_type]}" || exit 1