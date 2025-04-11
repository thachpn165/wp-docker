#!/usr/bin/env bash
# ✅ Load configuration from any directory
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

# Load functions for website management
source "$FUNCTIONS_DIR/website_loader.sh"

# Hàm restart website sử dụng domain từ _parse_params "--domain" 
function website_cli_restart() {
  local domain
  domain=$(_parse_params "--domain"  "$@")

  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi
  if [[ $? -eq 0 ]]; then
    website_logic_restart "$domain"
  fi
}

# Hàm hiển thị thông tin website sử dụng domain từ _parse_params "--domain" 
function website_cli_info() {
  local domain
  domain=$(_parse_params "--domain"  "$@")
  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi
  if [[ $? -eq 0 ]]; then
    website_logic_info "$domain"
  fi
}

# Website listing CLI
function website_cli_list() {
  website_logic_list "$domain"
}


# Website logs CLI
function website_cli_logs() {
  local domain
  local log_type

  log_type=$(_parse_params "--log_type" "$@")
  domain=$(_parse_params "--domain"  "$@")

  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain, --log_type"
    return 1
  fi
  if [[ $? -eq 0 ]]; then
    website_logic_logs "$domain" "$log_type"
  fi
}

# Website delete CLI
website_cli_delete() {
  local domain
  local backup_enabled

  domain=$(_parse_params "--domain"  "$@")
  backup_enabled=$(_parse_params "--backup_enabled" "$@")
  
  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi
  if [[ $? -eq 0 ]]; then
    website_logic_delete "$domain" "$backup_enabled"
  fi
}