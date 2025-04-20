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
safe_source "$FUNCTIONS_DIR/backup_loader.sh"
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
            1) backup_prompt_backup_web; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            2) backup_prompt_backup_manage; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            3) backup_prompt_create_schedule ;;
            4) backup_schedule_menu; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            5) backup_prompt_restore_web; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
            6) 
                break
                ;;
            *)
                print_msg error "$ERROR_SELECT_OPTION_INVALID"
                ;;
        esac
    done
}
