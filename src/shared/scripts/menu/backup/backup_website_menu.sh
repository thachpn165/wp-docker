#!/bin/bash
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/backup_loader.sh"

# 📋 Hiển thị danh sách website để chọn (dùng select_website)
select_website
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} No website selected.${NC}"
  exit 1
fi

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
            echo "${CROSSMARK} Invalid option. Please select either 'local' or 'cloud'."
            ;;
    esac
done

# === If cloud storage is selected, ask for rclone storage selection ===
if [[ "$storage" == "cloud" ]]; then
    echo -e "${YELLOW}📂 Fetching storage list from rclone.conf...${NC}"
    
    # Get list of storage names from rclone.conf, removing brackets
    mapfile -t rclone_storages < <(grep -o '^\[.*\]' "$RCLONE_CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/g')

    # Check if there are storages available
    if [[ ${#rclone_storages[@]} -eq 0 ]]; then
        echo -e "${RED}${CROSSMARK} No storage configured in rclone.conf! Please run 'wpdocker' > 'Rclone Management' > 'Setup Rclone' to configure Rclone.${NC}"
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
        echo -e "${RED}${CROSSMARK} Invalid selection. Exiting.${NC}"
        exit 1
    fi

    selected_storage="${rclone_storages[$selected_storage_index]}"
    echo "You selected storage: $selected_storage"
fi

# === Pass selected parameters to the backup logic ===
backup_website_logic "$domain" "$storage" "$selected_storage"
