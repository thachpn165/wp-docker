#!/bin/bash
# Import Rclone functions
safe_source "$SCRIPTS_FUNCTIONS_DIR/rclone/setup_rclone.sh"
safe_source "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh"
safe_source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"

# Function to display Rclone management menu
rclone_menu() {
    while true; do
        echo -e "${CYAN}============================${NC}"
        print_msg title "$TITLE_MENU_RCLONE"
        echo -e "${CYAN}============================${NC}"
        print_msg label "${GREEN}[1]${NC} ${STRONG}$LABEL_MENU_RCLONE_SETUP${NC}"
        print_msg label "${GREEN}[2]${NC} ${STRONG}$LABEL_MENU_RCLONE_LIST_STORAGE${NC}"
        print_msg label "${GREEN}[3]${NC} ${STRONG}$LABEL_MENU_RCLONE_DELETE_STORAGE${NC}"
        print_msg label "${GREEN}[4]${NC} ${STRONG}$MSG_EXIT${NC}"
        
        read -p "$MSG_SELECT_OPTION" choice

        case "$choice" in
            1) rclone_setup ;;
            2)
                echo ""
                print_msg label "$LABEL_MENU_RCLONE_AVAILABLE_STORAGE"
                echo ""
                rclone_storage_list
                echo ""
                ;;
            3) rclone_storage_delete ;;
            4)
                #print_msg progress "$MSG_EXITING"
                break
                ;;
            *)
                print_msg error "$MSG_INVALID_OPTION"
                sleep 1
                ;;
        esac
    done
}
