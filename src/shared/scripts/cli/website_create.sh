#!/bin/bash
# ==================================================
# File: website_create.sh
# Description: CLI to create a new website with WordPress.
# Functions:
#   - website_cli_create: Create a new website with WordPress.
#       Parameters:
#           --domain=<domain>: The domain name of the website.
#           --php=<version>: The PHP version to use.
#           [--auto_generate=true|false]: Optional flag to auto-generate WordPress setup (default: true).
#       Returns: None.
# ==================================================

# === Auto-detect BASE_DIR & load config ===
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

# === Load website logic ===
safe_source "$FUNCTIONS_DIR/website_loader.sh"

website_cli_create() {
  local domain php_version auto_generate
  auto_generate=true  # Default: true

  domain=$(_parse_params "--domain" "$@")
  php_version=$(_parse_params "--php" "$@")
  auto_generate=$(_parse_params "--auto_generate" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$php_version" "--php" || return 1
  _is_valid_domain "$domain" || return 1

  # === Execute creation logic ===
  website_logic_create "$domain" "$php_version"
  website_setup_wordpress_logic "$domain" "$auto_generate"
}