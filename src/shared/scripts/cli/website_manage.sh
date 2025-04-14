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

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  website_logic_restart "$domain"
}

# =====================================
# ℹ️ website_cli_info – Show website info
# Params: --domain
# =====================================
website_cli_info() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

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

  if [[ -z "$domain" || -z "$log_type" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain, --log_type"
    return 1
  fi

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

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  website_logic_delete "$domain" "$backup_enabled"
}