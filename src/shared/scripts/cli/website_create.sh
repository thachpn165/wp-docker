#!/usr/bin/env bash
#shellcheck disable=SC1091

# =====================================
# 🏗 website_cli_create – CLI to create new website with WordPress
# Parameters:
#   --domain=<domain>
#   --php=<version>
#   [--auto_generate=true|false]
# =====================================

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

  # === Debug info ===
  debug_log "[website_cli_create] Domain: $domain"
  debug_log "[website_cli_create] PHP Version: $php_version"
  debug_log "[website_cli_create] Auto-generate: $auto_generate"
  debug_log "[website_cli_create] Website creation completed"
}

