#!/bin/bash

# =====================================
# 🚀 wordpress_cache_cli.sh – CLI wrapper to configure WordPress cache
# Parameters:
#   --domain=<domain>
#   --cache_type=<fastcgi-cache|wp-super-cache|no-cache|...>
# =====================================

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

# === Load WordPress logic functions ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

wordpress_cli_cache_setup() {
  local domain="$1"
  local cache_type="$2"
  if [[ -z "$domain" || -z "$cache_type" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain & --cache_type"
    exit 1
  fi
  # Call the logic function to set up the cache
  wordpress_cache_setup_logic "$domain" "$cache_type"
}
