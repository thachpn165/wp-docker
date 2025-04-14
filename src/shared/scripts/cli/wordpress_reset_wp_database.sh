#!/bin/bash

# =============================================
# 💥 wordpress_reset_wp_database.sh – Reset WordPress database for a website
# =============================================
# Description:
#   - Drops and recreates the WordPress database for a specified site.
#
# Usage:
#   ./wordpress_reset_wp_database.sh --domain=example.tld
#
# Parameters:
#   --domain=<domain>   (required) The name of the site whose DB will be reset
# =============================================

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

# === Load WordPress-related functions ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse parameters ===
domain=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*) domain="${1#*=}" ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
  shift
done

# === Validate required parameter ===
if [[ -z "$domain" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Execute logic ===
wordpress_reset_wp_database_logic "$domain"