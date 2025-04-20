#!/usr/bin/env bash

# =====================================
# 🌐 website_cli.sh – CLI wrappers for website management
# =====================================

# === Load config from any directory ===
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

# === Load website logic functions ===
safe_source "$FUNCTIONS_DIR/website_loader.sh"

# =====================================
# 🔁 website_cli_restart – Restart a website
# Params: --domain
# =====================================
website_cli_restart() {
  local domain
  domain=$(_parse_params "--domain" "$@")
  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1

  website_logic_restart "$domain"
}

# =====================================
# ℹ️ website_cli_info – Show website info
# Params: --domain
# =====================================
website_cli_info() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1
  website_logic_info "$domain"
}

# =====================================
# 📃 website_cli_list – List all websites
# =====================================
website_cli_list() {
  website_logic_list
}

# =====================================
# 📜 website_cli_logs – View site logs
# Params: --domain, --log_type
# =====================================
website_cli_logs() {
  local domain log_type
  domain=$(_parse_params "--domain" "$@")
  log_type=$(_parse_params "--log_type" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$log_type" "--log_type" || return 1
  _is_valid_domain "$domain" || return 1

  website_logic_logs "$domain" "$log_type"
}

# =====================================
# ❌ website_cli_delete – Delete a website
# Params: --domain, --backup_enabled=true|false
# =====================================
website_cli_delete() {
  local domain backup_enabled
  domain=$(_parse_params "--domain" "$@")
  backup_enabled=$(_parse_params "--backup_enabled" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$backup_enabled" "--backup_enabled" || return 1
  _is_valid_domain "$domain" || return 1

  website_logic_delete "$domain" "$backup_enabled"
}
