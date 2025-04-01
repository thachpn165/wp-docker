#!/usr/bin/env bash

# ============================================
# ✅ website_logs_menu.sh – View logs for a WordPress website via Menu
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

# === Prompt user for logs option (e.g., access logs or error logs) ===
echo -e "${YELLOW}⚡ You are about to view logs for the website '$site_name'. Choose log type:${NC}"
echo "1. Access Logs"
echo "2. Error Logs"
read -p "Select an option (1/2): " log_option

# === Set --log_type parameter based on user input ===
if [[ "$log_option" == "1" ]]; then
  log_type="access"
elif [[ "$log_option" == "2" ]]; then
  log_type="error"
else
  echo -e "${RED}❌ Invalid option selected.${NC}"
  exit 1
fi

# === Call the CLI with --log_type parameter ===
echo -e "${GREEN}📄 Displaying $log_type logs for $site_name...${NC}"
bash "$SCRIPTS_DIR/cli/website_logs.sh" --site_name="$site_name" --log_type="$log_type"