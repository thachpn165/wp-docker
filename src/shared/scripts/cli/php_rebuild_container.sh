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

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
    exit 1
  fi

  php_rebuild_container_logic "$domain"
}