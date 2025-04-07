#!/bin/bash
# Import backup functions
# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for website management
source "$FUNCTIONS_DIR/backup_loader.sh"
# Function to display backup management menu
backup_menu() {
    while true; do
        echo -e "${CYAN}============================${NC}"
        print_msg title "$TITLE_MENU_BACKUP"
        echo -e "${CYAN}============================${NC}"
        print_msg label "${GREEN}1)${NC} $LABEL_MENU_BACKUP_NOW"
        print_msg label "${GREEN}2)${NC} $LABEL_MENU_BACKUP_MANAGE"
        print_msg label "${GREEN}3)${NC} $LABEL_MENU_BACKUP_SCHEDULE"
        print_msg label "${GREEN}4)${NC} $LABEL_MENU_BACKUP_SCHEDULE_MANAGE"
        print_msg label "${GREEN}5)${NC} $LABEL_MENU_BACKUP_RESTORE"
        print_msg label "${GREEN}6)${NC} $MSG_BACK"
        echo -e "${CYAN}============================${NC}"
        
        read -p "$MSG_SELECT_OPTION " choice

    
        case "$choice" in
            1) bash "$MENU_DIR/backup/backup_website_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            2) bash "$MENU_DIR/backup/backup_manage_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            3) bash "$MENU_DIR/backup/backup_scheduler_create_menu.sh" ;;
            4) manage_cron_menu; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            5) bash "$MENU_DIR/backup/backup_restore_web_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            6) 
                break
                ;;
            *)
                print_msg error "$ERROR_SELECT_OPTION_INVALID"
                ;;
        esac
    done
}
