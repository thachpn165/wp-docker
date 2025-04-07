#!/usr/bin/env bash

# ============================================
# ${CHECKMARK} website_restart_menu.sh – Restart a WordPress website via Menu
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
  print_msf error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# === Ask the user if they want to restart the selected website ===
echo -e "${YELLOW}⚡ You are about to restart the website '$domain'. Are you sure?${NC}"
confirm_action "Do you want to proceed?"

if [[ $? -eq 0 ]]; then
  # === Call the CLI for restarting the website, pass --domain correctly ===
  echo -e "${GREEN}${CHECKMARK} Restarting website '$domain'...${NC}"
  bash "$SCRIPTS_DIR/cli/website_restart.sh" --domain="$domain"  # Fixed here, passing --site
  echo -e "${GREEN}${CHECKMARK} Website '$domain' has been restarted successfully.${NC}"
else
  echo -e "${YELLOW}${WARNING} Website restart cancelled.${NC}"
fi