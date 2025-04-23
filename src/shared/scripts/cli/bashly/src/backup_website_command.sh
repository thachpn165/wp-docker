safe_source "$CLI_DIR/backup_website.sh"

backup_cli_backup_web --domain="${args[domain]}" --storage="${args[storage]}" --rclone_storage="${args[rclone_storage]}"