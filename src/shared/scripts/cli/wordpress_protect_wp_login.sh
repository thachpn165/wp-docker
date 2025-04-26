#!/bin/bash
# ==================================================
# File: wordpress_protect_wp_login.sh
# Description: CLI to protect or unprotect `wp-login.php` by enabling or disabling authentication.
# Functions:
#   - wordpress_cli_protect_wplogin: Protect or unprotect `wp-login.php` for a WordPress site.
#       Parameters:
#           --domain=<domain>: The domain name of the WordPress site.
#           --action=<enable|disable>: The action to perform (enable or disable protection).
#       Returns: None.
# ==================================================

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

wordpress_cli_protect_wplogin() {
  local domain action
  domain=$(_parse_params "--domain" "$@")
  action=$(_parse_params "--action" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$action" "--action" || return 1
  _is_valid_domain "$domain" || return 1

  wordpress_protect_wp_login_logic "$domain" "$action"
}