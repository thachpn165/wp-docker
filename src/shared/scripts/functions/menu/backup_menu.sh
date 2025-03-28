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
    echo "❌ Config file not found at: $CONFIG_FILE" >&2
    exit 1
fi
source "$CONFIG_FILE"

# Import backup functions
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_actions.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_restore_web.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/schedule_backup.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/manage_cron.sh"

# Function to display backup management menu
backup_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   🛠️ WEBSITE BACKUP MANAGEMENT   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} Backup website now"
        echo -e "  ${GREEN}[2]${NC} Delete old backups"
        echo -e "  ${GREEN}[3]${NC} View backup list"
        echo -e "  ${GREEN}[4]${NC} Schedule automatic backup"
        echo -e "  ${GREEN}[5]${NC} Manage backup schedule (Crontab)"
        echo -e "  ${GREEN}[6]${NC} Restore website from backup"
        echo -e "  ${GREEN}[7]${NC} ❌ Exit"
        echo -e "${BLUE}============================${NC}"
        
        read -p "🔹 Select an option (1-6): " choice

        case "$choice" in
            1) backup_website ;;
            2) cleanup_old_backups ;;
            3) list_backup_files ;;
            4) schedule_backup_create ;;
            5) manage_cron_menu ;;
            6) backup_restore_web ;;
            7) 
                echo -e "${GREEN}👋 Exiting Backup menu!${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Invalid option, please try again!${NC}"
                ;;
        esac
    done
}
