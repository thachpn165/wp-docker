#!/bin/bash

# =====================================
# 🔁 php_cli_rebuild_container – CLI wrapper to rebuild PHP container for a site
# Parameters:
#   --domain=<domain>
# =====================================

# === Load logic (uncomment if needed) ===
# safe_source "$FUNCTIONS_DIR/php_loader.sh"

php_cli_rebuild_container() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1

  php_rebuild_container_logic "$domain"
}