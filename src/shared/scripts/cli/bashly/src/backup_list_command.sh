safe_source "$CLI_DIR/backup_manage.sh"

backup_cli_manage --domain="${args[domain]}" --action=list || exit 1