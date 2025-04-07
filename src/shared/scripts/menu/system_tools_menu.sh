#!/bin/bash
source "$FUNCTIONS_DIR/system_loader.sh"


print_system_tools_menu_header() {
    echo -e "\n${MAGENTA}===========================================${NC}"
    print_msg title "$TITLE_MENU_SYSTEM"
    echo -e "${MAGENTA}===========================================${NC}"
}

system_tools_menu() {
    while true; do
        print_system_tools_menu_header
        print_msg label "${GREEN}1)${NC} $LABEL_MENU_SYSTEM_CHECK"
        print_msg label "${GREEN}2)${NC} $LABEL_MENU_SYSTEM_MANAGE_DOCKER"
        print_msg label "${GREEN}3)${NC} $LABEL_MENU_SYSTEM_CLEANUP_DOCKER"
        print_msg label "${GREEN}4)${NC} $LABEL_MENU_SYSTEM_REBUILD_NGINX"
        print_msg label "${GREEN}[5]${NC} ${STRONG}$MSG_EXIT${NC}"
        echo ""
        read -p "$MSG_SELECT_OPTION " choice

        
            case $choice in
                1)
                    bash "$MENU_DIR/system-tools/system_check_resources_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                2)
                    bash "$MENU_DIR/system-tools/system_manage_docker_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                3)
                    bash "$CLI_DIR/system_cleanup_docker.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                4)
                    bash "$CLI_DIR/system_nginx_rebuild.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                5)
                    break
                    ;;
                *)
                    print_msg error "$ERROR_SELECT_OPTION_INVALID"
                    ;;
            esac
    done
}