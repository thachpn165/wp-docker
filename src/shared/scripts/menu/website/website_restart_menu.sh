#!/usr/bin/env bash

# ============================================
# ✅ website_restart_menu.sh – Restart a WordPress website via Menu
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
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

# === Display the list of websites to the user ===
select_website
site_name="$SITE_NAME"
if [[ -z "$site_name" ]]; then
  echo "❌ No website selected."
  exit 1
fi

# === Ask the user if they want to restart the selected website ===
echo -e "${YELLOW}⚡ You are about to restart the website '$site_name'. Are you sure?${NC}"
confirm_action "Do you want to proceed?"

if [[ $? -eq 0 ]]; then
  # === Call the CLI for restarting the website, pass --site_name correctly ===
  echo -e "${GREEN}✅ Restarting website '$site_name'...${NC}"
  bash "$SCRIPTS_DIR/cli/website_restart.sh" --site_name="$site_name"  # Fixed here, passing --site
  echo -e "${GREEN}✅ Website '$site_name' has been restarted successfully.${NC}"
else
  echo -e "${YELLOW}⚠️ Website restart cancelled.${NC}"
fi