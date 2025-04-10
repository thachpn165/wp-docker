#!/usr/bin/env bash
# shellcheck disable=SC1091

# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for website management
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument ===
domain="$(website_domain_param "$@")"
backup_enabled="$(website_backup_enabled_param "$@")"

if [[ $? -ne 0 ]]; then
  print_msg error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Run deletion logic ===
website_logic_delete "$domain" "$backup_enabled"
