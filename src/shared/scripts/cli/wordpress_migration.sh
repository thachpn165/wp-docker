#!/bin/bash
# ==================================================
# File: wordpress_migration.sh
# Description: CLI wrapper to migrate a WordPress website.
# Functions:
#   - wordpress_cli_migration: Migrate a WordPress website to a new environment.
#       Parameters:
#           --domain=<domain>: The domain name of the WordPress site to migrate.
#       Returns: None.
# ==================================================

# === Auto-detect BASE_DIR & load configuration ===
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

wordpress_cli_migration() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1

  wordpress_migration_logic "$domain"
}