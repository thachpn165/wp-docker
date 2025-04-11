#!/bin/bash
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/php_loader.sh"

php_cli_change_version() {
  local domain
  local php_version
  
  domain=$(_parse_params "--domain" "$@")
  php_version=$(_parse_params "--php_version" "$@")


  # Validate parameters
  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain, --php_version"
    exit 1
  fi

  # Call the logic function
  php_logic_change_version "$domain" "$php_version"
}

