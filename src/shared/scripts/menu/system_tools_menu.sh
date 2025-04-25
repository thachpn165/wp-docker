#!/bin/bash
safe_source "$FUNCTIONS_DIR/system_loader.sh"
safe_source "$CLI_DIR/system_tools.sh"


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
        print_msg label "${GREEN}5)${NC} $LABEL_MENU_SYSTEM_CHANGE_LANG"
        print_msg label "${GREEN}6)${NC} $LABEL_MENU_SYSTEM_CHANGE_CHANNEL"
        print_msg label "${GREEN}[7]${NC} ${STRONG}$MSG_EXIT${NC}"
        echo ""
        read -p "$MSG_SELECT_OPTION " choice

        
            case $choice in
                1)
                    system_cli_check_resources; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                2)
                    system_prompt_manage_docker; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                3)
                    system_cli_cleanup_docker; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                4)
                    system_cli_nginx_rebuild; read -p "$MSG_PRESS_ENTER_CONTINUE"
                    ;;
                5)
                    core_lang_change_prompt; read -p "$MSG_PRESS_ENTER_CONTINUE"; exit 0
                    ;;
                6)
                    core_channel_switch_prompt; read -p "$MSG_PRESS_ENTER_CONTINUE"; exit 0
                    ;;
                7)
                    break
                    ;;
                *)
                    print_msg error "$ERROR_SELECT_OPTION_INVALID"
                    ;;
            esac
    done
}