#!/bin/bash
# filepath: /Users/thachpham/wp-docker-lemp/src/shared/scripts/cli/backup_website.sh
# ==================================================
# File: backup_website.sh
# Description: CLI wrapper to manage website backups, including backing up WordPress files 
#              and performing full website backups (files + database + optional cloud storage).
# Functions:
#   - backup_cli_file: Backup only WordPress files for a specific domain.
#       Parameters:
#           --domain=<domain>: The domain name of the website to back up.
#       Returns: 0 if successful, 1 otherwise.
#   - backup_cli_backup_web: Perform a full website backup (files + database + optional rclone).
#       Parameters:
#           --domain=<domain>: The domain name of the website to back up.
#           --storage=<local|cloud>: The storage type for the backup.
#           [--rclone_storage=<name>]: Optional rclone storage name for cloud backups.
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

# Load backup logic
safe_source "$FUNCTIONS_DIR/backup_loader.sh"

backup_cli_file() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1

  backup_file_logic "$domain"
}

backup_cli_backup_web() {
  local domain storage rclone_storage

  domain=$(_parse_params "--domain" "$@")
  storage=$(_parse_params "--storage" "$@")
  rclone_storage=$(_parse_optional_params "--rclone_storage" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$storage" "--storage" || return 1
  _is_valid_domain "$domain" || return 1

  backup_logic_website "$domain" "$storage" "$rclone_storage"
}