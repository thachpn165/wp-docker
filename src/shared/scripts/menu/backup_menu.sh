#!/bin/bash

# === 🧠 Auto-detect PROJECT_DIR (source code root) ===

if [[ -z "$PROJECT_DIR" ]]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
    while [[ "$SCRIPT_PATH" != "/" && ! -f "$SCRIPT_PATH/shared/config/config.sh" ]]; do
        SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
    done
    PROJECT_DIR="$SCRIPT_PATH"
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
    exit 1
fi
source "$CONFIG_FILE"

# Import backup functions
source "$SCRIPTS_FUNCTIONS_DIR/backup/manage_cron.sh"

# Function to display backup management menu
backup_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   🛠️ WEBSITE BACKUP MANAGEMENT   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} Backup website now"
        echo -e "  ${GREEN}[2]${NC} Manage Backup (Cleanup, List)"
        echo -e "  ${GREEN}[3]${NC} Schedule automatic backup"
        echo -e "  ${GREEN}[4]${NC} Manage backup schedule (Crontab)"
        echo -e "  ${GREEN}[5]${NC} Restore website from backup"
        echo -e "  ${GREEN}[6]${NC} ${CROSSMARK} Exit"
        echo -e "${BLUE}============================${NC}"
        
        [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-6): " choice

        case "$choice" in
            1) bash "$MENU_DIR/backup/backup_website_menu.sh" ;;
            2) bash "$MENU_DIR/backup/backup_manage_menu.sh" ;;
            3) bash "$MENU_DIR/backup/backup_scheduler_create_menu.sh" ;;
            4) manage_cron_menu ;;
            5) bash "$MENU_DIR/backup/backup_restore_web_menu.sh" ;;
            6) 
                echo -e "${GREEN}👋 Exiting Backup menu!${NC}"
                break
                ;;
            *)
                echo -e "${RED}${CROSSMARK} Invalid option, please try again!${NC}"
                ;;
        esac
    done
}
