#!/usr/bin/env bash

# ============================================
# ${CHECKMARK} website_info_menu.sh – Show information of a WordPress website via Menu
# ============================================

# === Load config & website_loader.sh ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

# === Display the list of websites to the user ===
select_website
if [[ -z "$domain" ]]; then
  echo "${CROSSMARK} No website selected."
  exit 1
fi

# === Show the website information using the CLI script ===
echo -e "${YELLOW}⚡ You are about to view the information of the website '$domain'.${NC}"

# Call the CLI script with the --domain parameter
bash "$SCRIPTS_DIR/cli/website_info.sh" --domain="$domain"