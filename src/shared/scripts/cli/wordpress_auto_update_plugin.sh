#!/bin/bash
#shellcheck disable=SC1091

# =====================================
# 🧱 website_cli_update_template – Update NGINX template for a website
# Parameters:
#   --domain=<domain>
#   --action=<rebuild|reset|...>
# =====================================

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

# === Load WordPress-related logic functions ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

website_cli_update_template() {
  local domain action

  # === Parse CLI parameters ===
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --domain=*) domain="${1#*=}" ;;
      --action=*) action="${1#*=}" ;;
      *) 
        print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
        exit 1
        ;;
    esac
    shift
  done

  # === Validate required parameters ===
  if [[ -z "$domain" || -z "$action" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain & --action"
    exit 1
  fi

  # === Execute logic ===
  website_logic_update_template "$domain" "$action"
}