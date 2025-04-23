safe_source "$CLI_DIR/website_manage.sh"

website_cli_delete --domain="${args[domain]}" \
    --backup_enabled="${args[backup]}"