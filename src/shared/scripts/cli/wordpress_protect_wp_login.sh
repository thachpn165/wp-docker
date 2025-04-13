#!/bin/bash

# ============================================
# 🔐 wordpress_protect_wp_login.sh – CLI to protect/unprotect wp-login.php
# ============================================
# Description:
#   - Enables or disables authentication for wp-login.php
#   - Works by injecting/removing nginx include config and htpasswd
#
# Parameters:
#   --domain=<example.tld>   (required)
#   --action=enable|disable  (required)
#
# Usage:
#   ./wordpress_protect_wp_login.sh --domain=example.com --action=enable
# ============================================

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

# === Load WordPress-related logic ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse parameters ===
domain=""
action=""

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

# === Validate parameters ===
if [[ -z "$domain" || -z "$action" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain and --action"
  exit 1
fi

# === Execute logic ===
wordpress_protect_wp_login_logic "$domain" "$action"