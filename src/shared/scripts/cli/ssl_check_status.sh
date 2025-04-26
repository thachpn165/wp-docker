#!/bin/bash
# ==================================================
# File: ssl_check_status.sh
# Description: CLI wrapper to check the SSL certificate status for a specific domain.
# Functions:
#   - ssl_cli_check_status: Check SSL certificate status for a domain.
#       Parameters:
#           --domain=<domain>: The domain name to check.
#       Returns: None.
# ==================================================

# === Auto-detect BASE_DIR & load config ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load SSL logic functions ===
safe_source "$FUNCTIONS_DIR/ssl_loader.sh"

ssl_cli_check_status() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1

  ssl_logic_check_cert "$domain"
}