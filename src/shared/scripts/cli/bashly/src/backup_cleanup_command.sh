safe_source "$FUNCTIONS_DIR/backup/backup_manage.sh"

backup_logic_manage "${args[domain]}" clean "${args[max_age_days]}" || exit 1