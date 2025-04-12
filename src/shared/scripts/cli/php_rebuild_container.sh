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
#source "$FUNCTIONS_DIR/php_loader.sh"

php_cli_rebuild_container() {
  local domain
  # Parse command line flags
  domain=$(_parse_params "--domain" "$@")
  debug_log "Domain: $domain"
  # Ensure valid parameters are passed
  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
    exit 1
  fi

  # Call the logic function to rebuild the PHP container
  php_rebuild_container_logic "$domain"
}
