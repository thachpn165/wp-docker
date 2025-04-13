#!/bin/bash

# =====================================
# 🚀 wordpress_cache_cli.sh – CLI wrapper to configure WordPress cache
# Parameters:
#   --domain=<domain>
#   --cache_type=<fastcgi-cache|wp-super-cache|no-cache|...>
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

# === Load WordPress logic functions ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse parameters ===
domain=""
cache_type=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)     domain="${1#*=}" ;;
    --cache_type=*) cache_type="${1#*=}" ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
  shift
done

# === Validate required parameters ===
if [[ -z "$domain" || -z "$cache_type" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain & --cache_type"
  exit 1
fi

# === Execute logic ===
wordpress_cache_setup_logic "$domain" "$cache_type"