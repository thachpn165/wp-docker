#!/usr/bin/env bash
#shellcheck disable=SC1091

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
safe_source "$FUNCTIONS_DIR/website_loader.sh"

website_cli_create() {
  auto_generate=true # default: true
  domain=$(_parse_params "--domain"  "$@")
  php_version=$(_parse_params "--php" "$@")
  auto_generate=$(_parse_params "--auto_generate" "$@")

  if [[ -z "$domain" || -z "$php_version" ]]; then
    #echo "${CROSSMARK} Missing parameters. Usage:"
    print_msg error "$ERROR_MISSING_PARAM: --domain & --php"
    exit 1
  fi

  website_logic_create "$domain" "$php_version"
  website_setup_wordpress_logic "$domain" "$auto_generate"

  ## Debugging
  debug_log "Domain: $domain"
  debug_log "PHP Version: $php_version"
  debug_log "Auto-generate: $auto_generate"
  debug_log "Website creation process completed."
}


