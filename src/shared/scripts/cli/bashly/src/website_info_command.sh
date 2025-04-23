safe_source "$CLI_DIR/website_manage.sh"

website_cli_info --domain="${args[domain]}" || exit 1