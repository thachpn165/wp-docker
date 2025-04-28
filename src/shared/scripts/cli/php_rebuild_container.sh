#!/bin/bash
# ==================================================
# File: php_rebuild_container.sh
# Description: CLI wrapper to rebuild the PHP container for a specific site.
# Functions:
#   - php_cli_rebuild_container: Rebuild the PHP container for a given domain.
#       Parameters:
#           --domain=<domain>: The domain name of the site.
#       Returns: None.
# ==================================================

# === Load logic (uncomment if needed) ===
# safe_source "$FUNCTIONS_DIR/php_loader.sh"

php_cli_rebuild_container() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1

  php_rebuild_container_logic "$domain"
}