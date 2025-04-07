#!/usr/bin/env bash

# ============================================
# ${CHECKMARK} website_info_menu.sh – Show information of a WordPress website via Menu
# ============================================
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

# === Display the list of websites to the user ===
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# Call the CLI script with the --domain parameter
bash "$SCRIPTS_DIR/cli/website_info.sh" --domain="$domain"