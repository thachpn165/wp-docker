#!/bin/bash
# ==================================================
# File: wordpress_cache_setup.sh
# Description: CLI wrapper to configure WordPress cache for a specific domain.
# Functions:
#   - wordpress_cli_cache_setup: Configure the cache type for a WordPress site.
#       Parameters:
#           --domain=<domain>: The domain name of the WordPress site.
#           --cache_type=<type>: The cache type to configure (e.g., fastcgi-cache, wp-super-cache, no-cache).
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

# === Load WordPress logic functions ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

wordpress_cli_cache_setup() {
  local domain cache_type

  # Parse parameters
  domain=$(_parse_params "--domain" "$@")
  cache_type=$(_parse_params "--cache_type" "$@")

  # Validate required parameters
  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$cache_type" "--cache_type" || return 1
  _is_valid_domain "$domain" || return 1

  # Call the logic function to set up the cache
  wordpress_cache_setup_logic "$domain" "$cache_type"
}