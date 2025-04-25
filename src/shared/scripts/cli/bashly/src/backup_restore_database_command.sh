safe_source "$FUNCTIONS_DIR/backup/backup_restore_functions.sh"

backup_restore_database "${args[db_backup_file]}" "${args[domain]}" || exit 1