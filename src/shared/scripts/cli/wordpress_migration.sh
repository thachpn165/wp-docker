#!/bin/bash

# =====================================
# 🚚 wordpress_migration_cli.sh – CLI wrapper to migrate a WordPress website
# Parameters:
#   --domain=<domain>
# =====================================

# === Auto-detect BASE_DIR & load configuration ===
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

for arg in "$@"; do
  case "$arg" in
    --domain=*) domain="${arg#*=}" ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $arg"
      exit 1
      ;;
  esac
done

# === Validate required parameters ===
if [[ -z "$domain" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Execute migration logic ===
wordpress_migration_logic "$domain"