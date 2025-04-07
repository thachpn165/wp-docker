#!/bin/bash
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
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse arguments ===
domain=""
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    #*) echo "❌ Unknown argument: $arg" && exit 1 ;;
    *) 
      print_and_debug error "$ERROR_UNKNOW_PARAM: $arg"
      exit 1
      ;;
  esac
done

if [[ -z "$domain" ]]; then
 #echo "❌ Missing required parameter: --domain"
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Execute migration logic ===
wordpress_migration_logic "$domain"