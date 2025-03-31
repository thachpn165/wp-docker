#!/bin/bash

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
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Select website ===
select_website

# Ensure site is selected
if [[ -z "$SITE_NAME" ]]; then
    echo "❌ No website selected. Exiting."
    exit 1
fi

echo "Selected site: $SITE_NAME"

# === Choose action: list or clean ===
echo -e "${YELLOW}📂 Choose action:${NC}"
select action_choice in "list" "clean"; do
    case $action_choice in
        list)
            echo "You selected to list backups."
            action="list"
            break
            ;;
        clean)
            echo "You selected to clean old backups."
            action="clean"
            break
            ;;
        *)
            echo "❌ Invalid option. Please select either 'list' or 'clean'."
            ;;
    esac
done

# === If cleaning, ask for max age days ===
if [[ "$action" == "clean" ]]; then
    read -p "Enter the number of days to keep backups (default is 7): " max_age_days
    max_age_days="${max_age_days:-7}"  # Use default if not provided
    echo "You selected to keep backups for $max_age_days days."
fi

# === Execute the backup_manage logic with selected parameters ===
bash "$SCRIPTS_DIR/cli/backup_manage.sh" --site_name="$SITE_NAME" --action="$action" --max_age_days="$max_age_days"