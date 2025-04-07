#!/bin/bash
# Function to display backup management menu
database_menu() {
        while true; do
            echo -e "${CYAN}============================${NC}"
            print_msg title "$TITLE_MENU_DATABASE"
            echo -e "${CYAN}============================${NC}"
            print_msg label "${GREEN}1)${NC} $LABEL_MENU_DATABASE_RESET"
            print_msg label "${GREEN}2)${NC} $LABEL_MENU_DATABASE_EXPORT"
            print_msg label "${GREEN}3)${NC} $LABEL_MENU_DATABASE_IMPORT"
            print_msg label "${GREEN}6)${NC} $MSG_BACK"
            echo -e "${CYAN}============================${NC}"
            
            read -p "$MSG_SELECT_OPTION " choice
            
                case "$choice" in
                    1) bash "$MENU_DIR/database/database_reset_menu.sh"; 
                        read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
                    2) bash "$MENU_DIR/database/database_export_menu.sh"; 
                        read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
                    3) bash "$MENU_DIR/database/database_import_menu.sh"; 
                        read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
                    6) 
                        break
                        ;;
                    *)
                        print_msg error "$ERROR_SELECT_OPTION_INVALID"
                        sleep 1
                        ;;
                esac
        done
}
