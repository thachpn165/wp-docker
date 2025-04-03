#!/bin/bash

# === Load config & system_loader.sh ===
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
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# 📋 Display the list of websites to select (using select_website)
select_website
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} No website selected.${NC}"
  exit 1
fi

# 📋 **Choose the action to enable/disable protection for wp-login.php**
echo -e "${YELLOW}📋 Choose an action for the website '$domain':${NC}"
echo "1) Enable protection for wp-login.php"
echo "2) Disable protection for wp-login.php"
read -p "Enter the number corresponding to the action: " action_choice

if [ "$action_choice" == "1" ]; then
    action="enable"
elif [ "$action_choice" == "2" ]; then
    action="disable"
else
    echo -e "${RED}${CROSSMARK} Invalid choice.${NC}"
    exit 1
fi

# Pass parameters to CLI
bash "$SCRIPTS_DIR/cli/wordpress_protect_wp_login.sh" --domain="$domain" --action="$action"
