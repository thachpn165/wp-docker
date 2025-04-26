#!/bin/bash
# ==================================================
# File: backup_manage.sh
# Description: CLI wrapper to manage backups, including listing and cleaning backups.
# Functions:
#   - backup_cli_manage: Wrapper function to handle backup management logic.
#       Parameters:
#           --domain=<domain>: The domain name for the backup operation.
#           --action=<list|clean>: The action to perform (list or clean).
#       Returns: 0 if successful, 1 otherwise.
# ==================================================


#shellcheck disable=SC1091

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

backup_cli_manage() {
  local domain action

  domain=$(_parse_params "--domain" "$@")
  action=$(_parse_params "--action" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$action" "--action" || return 1
  _is_valid_domain "$domain" || return 1

  backup_logic_manage "$domain" "$action"
}