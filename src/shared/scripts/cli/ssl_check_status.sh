#!/usr/bin/env bash

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

# =====================================
# 🔐 ssl_cli_check_status – Check SSL certificate status for a domain
# Parameters:
#   --domain=<domain>
# =====================================

ssl_cli_check_status() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
    exit 1
  fi

  ssl_logic_check_cert "$domain"
}