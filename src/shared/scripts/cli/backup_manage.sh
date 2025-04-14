#!/bin/bash
#shellcheck disable=SC1091

# =====================================
# 🧠 backup_cli_manage.sh – CLI wrapper to manage backups (list, clean...)
# =====================================

# === Auto-detect BASE_DIR & load configuration ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load backup logic ===
safe_source "$FUNCTIONS_DIR/backup_loader.sh"

# =====================================
# 🚀 backup_cli_manage: Wrapper to call backup_logic_manage
# Parameters:
#   --domain=<domain>
#   --action=<list|clean>
# =====================================
backup_cli_manage() {
  local domain action

  domain=$(_parse_params "--domain" "$@")
  action=$(_parse_params "--action" "$@")

  if [[ -z "$domain" || -z "$action" ]]; then
    print_and_debug error "$ERROR_BACKUP_MANAGE_MISSING_PARAMS"
    print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --action=list|clean"
    exit 1
  fi

  backup_logic_manage "$domain" "$action"
}