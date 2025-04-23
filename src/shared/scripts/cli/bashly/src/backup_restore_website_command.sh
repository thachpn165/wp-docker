safe_source "$CLI_DIR/backup_restore.sh"

backup_cli_restore_web \
    --domain="${args[domain]}" \
    --code_backup_file="${args[code_backup_file]}" \
    --db_backup_file="${args[db_backup_file]}" \
    --test_mode="${args[test_mode]}"
