#!/bin/bash

# === Auto-detect BASE_DIR & load config ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load PHP logic ===
safe_source "$FUNCTIONS_DIR/php_loader.sh"

# =====================================
# 🌀 php_cli_change_version – CLI wrapper to change PHP version for a site
# Parameters:
#   --domain=<domain>
#   --php_version=<version>
# =====================================

php_cli_change_version() {
  local domain php_version

  domain=$(_parse_params "--domain" "$@")
  php_version=$(_parse_params "--php_version" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$php_version" "--php_version" || return 1
  _is_valid_domain "$domain" || return 1

  php_logic_change_version "$domain" "$php_version"
}