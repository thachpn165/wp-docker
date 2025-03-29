#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Determine absolute path of `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Error: config.sh not found!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# Import Rclone functions
source "$SCRIPTS_FUNCTIONS_DIR/rclone/setup_rclone.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"

# Function to display Rclone management menu
rclone_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   📤 RCLONE MANAGEMENT   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} Setup Rclone"
        echo -e "  ${GREEN}[2]${NC} Upload Backup to Storage"
        echo -e "  ${GREEN}[3]${NC} View Storage List"
        echo -e "  ${GREEN}[4]${NC} Delete Configured Storage"
        echo -e "  ${GREEN}[5]${NC} ❌ Exit"
        echo -e "${BLUE}============================${NC}"
        
        read -p "🔹 Select an option (1-5): " choice

        case "$choice" in
            1) rclone_setup ;;
            2) bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" ;;
            3) echo ""
                echo "Available Storage List"
                echo ""
                rclone_storage_list 
                echo "";;
                
            4) rclone_storage_delete ;;
            5) echo -e "${GREEN}👋 Exiting Rclone menu!${NC}"; break ;;
            *) echo -e "${RED}❌ Invalid option, please try again!${NC}" ;;
        esac
    done
}
