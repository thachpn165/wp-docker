#!/bin/bash

# ============================================
# 🔐 wordpress_cli_protect_wplogin function– CLI to protect/unprotect wp-login.php
# ============================================
# Description:
#   - Enables or disables authentication for wp-login.php
#   - Works by injecting/removing nginx include config and htpasswd
#
# Parameters:
#   --domain=<example.tld>   (required)
#   --action=enable|disable  (required)
#
# Usage:
#   ./wordpress_protect_wp_login.sh --domain=example.com --action=enable
# ============================================

# === Auto-detect BASE_DIR and load configuration ===
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

# === Load WordPress-related logic ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

wordpress_cli_protect_wplogin () {
  local domain action
  domain=$(_parse_params "--domain" "$@")
  action=$(_parse_params "--action" "$@")

  # === Validate required parameters ===
  if [[ -z "$domain" || -z "$action" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain, --action"
    print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld --action=enable|disable"
    exit 1
  fi

  # === Execute logic ===
  wordpress_protect_wp_login_logic "$domain" "$action"
}
