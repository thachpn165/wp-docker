#!/bin/bash
#shellcheck disable=SC1091

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
safe_source "$FUNCTIONS_DIR/backup_loader.sh"

backup_cli_manage() {
  local domain
  local action
  # Parse parameters

  domain=$(_parse_params "--domain" "$@")
  action=$(_parse_params "--action" "$@")

  # Ensure valid parameters are passed
  if [[ -z "$domain" || -z "$action" ]]; then
    print_and_debug error "$ERROR_BACKUP_MANAGE_MISSING_PARAMS"
    print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --action=list/clean\n"
    exit 1
  fi

  # Call the backup_manage function with the passed parameters
  backup_logic_manage "$domain" "$action"
}
