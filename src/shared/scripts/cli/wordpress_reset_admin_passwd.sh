#!/bin/bash

# =============================================
# 🔐 wordpress_reset_admin_passwd.sh – Reset admin password for WordPress site
# =============================================
# Description:
#   - Resets the password for a specified WordPress user on a given domain.
#
# Parameters:
#   --domain=<domain>     (required)
#   --user_id=<user_id>   (required)
#
# Usage Example:
#   ./wordpress_reset_admin_passwd.sh --domain=example.tld --user_id=1
# =============================================

# === Auto-detect BASE_DIR & load configuration ===
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

# === Load WordPress logic functions ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

wordpress_cli_reset_admin_passwd() {
  local domain user_id
  domain=$(_parse_params "--domain" "$@")
  user_id=$(_parse_params "--user_id" "$@")
  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$user_id" "user_id" || return 1
  _is_valid_domain "$domain" || return 1

  if ! [[ "$user_id" =~ ^[1-9][0-9]*$ ]]; then
    print_msg error "$ERROR_WP_USER_ID_INVALID"
    return 1
  fi
  # === Execute logic to reset password ===
  reset_admin_password_logic "$domain" "$user_id"
}
