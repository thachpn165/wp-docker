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

# === Choose storage: local or cloud ===
echo -e "${YELLOW}📂 Choose storage option:${NC}"
select storage_choice in "local" "cloud"; do
    case $storage_choice in
        local)
            echo "You selected local storage."
            storage="local"
            break
            ;;
        cloud)
            echo "You selected cloud storage."
            storage="cloud"
            break
            ;;
        *)
            echo "❌ Invalid option. Please select either 'local' or 'cloud'."
            ;;
    esac
done

# === If cloud storage is selected, ask for rclone storage selection ===
if [[ "$storage" == "cloud" ]]; then
    echo -e "${YELLOW}📂 Fetching storage list from rclone.conf...${NC}"
    
    # Get list of storage names from rclone.conf, removing brackets
    rclone_storages=($(grep -o '^\[.*\]' "$RCLONE_CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/g'))

    # Check if there are storages available
    if [[ ${#rclone_storages[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No storage configured in rclone.conf! Please run 'wpdocker' > 'Rclone Management' > 'Setup Rclone' to configure Rclone.${NC}"
        exit 1
    fi

    # Display list of available rclone storages
    echo -e "${BLUE}Available Rclone Storages:${NC}"
    for i in "${!rclone_storages[@]}"; do
        echo "[$i] ${rclone_storages[$i]}"
    done

    # Prompt the user to select a storage
    read -p "Select storage (number): " selected_storage_index

    if [[ -z "${rclone_storages[$selected_storage_index]}" ]]; then
        echo -e "${RED}❌ Invalid selection. Exiting.${NC}"
        exit 1
    fi

    selected_storage="${rclone_storages[$selected_storage_index]}"
    echo "You selected storage: $selected_storage"
fi

# === Pass selected parameters to the backup logic ===
backup_website_logic "$SITE_NAME" "$storage" "$selected_storage"
