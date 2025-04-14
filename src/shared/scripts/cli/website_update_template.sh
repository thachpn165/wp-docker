#!/bin/bash

# =====================================
# 🎨 update_template.sh – Update NGINX template for a website
# =====================================
# Description:
#   - Locate and load config automatically
#   - Parse --domain parameter
#   - Call website_logic_update_template
#
# Usage:
#   ./update_template.sh --domain=example.com
#
# Required:
#   --domain=<site>
# =====================================

# === Auto-detect BASE_DIR & load config ===
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

# === Load website functions ===
safe_source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse arguments ===
domain=""
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
  esac
done

# === Validate domain parameter ===
if [[ -z "$domain" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Execute logic ===
website_logic_update_template "$domain"