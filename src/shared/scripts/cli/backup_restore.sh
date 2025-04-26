#!/bin/bash
# ==================================================
# File: backup_restore.sh
# Description: CLI wrapper to restore a website from backup files, including code and database backups.
# Functions:
#   - backup_cli_restore_web: Restore a website from code and database backup files.
#       Parameters:
#           --domain=<domain>: The domain name of the website to restore.
#           --code_backup_file=<path to .tar.gz>: Path to the code backup file.
#           --db_backup_file=<path to .sql>: Path to the database backup file.
#           [--test_mode=true]: Optional flag to enable test mode.
#       Returns: 0 if successful, 1 otherwise.
# ==================================================


# Auto-detect BASE_DIR & load configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# Load logic functions for backup
safe_source "$FUNCTIONS_DIR/backup_loader.sh"

backup_cli_restore_web() {
  local domain code_backup_file db_backup_file test_mode

  domain=$(_parse_params "--domain" "$@")
  code_backup_file=$(_parse_params "--code_backup_file" "$@")
  db_backup_file=$(_parse_params "--db_backup_file" "$@")
  test_mode=$(_parse_optional_params "--test_mode" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$code_backup_file" "--code_backup_file" || return 1
  _is_missing_param "$db_backup_file" "--db_backup_file" || return 1
  _is_valid_domain "$domain" || return 1

  # Call restore logic
  backup_logic_restore_web "$domain" "$code_backup_file" "$db_backup_file" "$test_mode"
}