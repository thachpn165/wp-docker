#!/bin/bash
safe_source "$FUNCTIONS_DIR/ssl_loader.sh"
# Header menu
print_ssl_menu_header() {
    echo -e "\n${MAGENTA}===========================================${NC}"
    print_msg title "$TITLE_MENU_SSL"
    echo -e "${MAGENTA}===========================================${NC}"
}

# Display menu
ssl_menu() {
    while true; do
        print_ssl_menu_header
        print_msg label "${GREEN}1)${NC} $LABEL_MENU_SSL_SELFSIGNED"
        print_msg label "${GREEN}2)${NC} $LABEL_MENU_SSL_MANUAL"
        print_msg label "${GREEN}3)${NC} $LABEL_MENU_SSL_LETSENCRYPT"
        print_msg label "${GREEN}4)${NC} $LABEL_MENU_SSL_EDIT"
        print_msg label "${GREEN}5)${NC} $LABEL_MENU_SSL_CHECK"
        print_msg label "${GREEN}6)${NC} $MSG_BACK"
        echo ""

        read -p "$MSG_SELECT_OPTION " choice
        case "$choice" in
            1)
                ssl_prompt_general "ssl_logic_install_selfsigned"
                [[ "$TEST_MODE" != true ]] && read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            2)
                ssl_prompt_general "ssl_logic_install_manual"
                [[ "$TEST_MODE" != true ]] && read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            3)
                ssl_prompt_general "ssl_logic_install_letsencrypt"
                [[ "$TEST_MODE" != true ]] && read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            4)
                ssl_prompt_general "ssl_logic_edit_cert"
                [[ "$TEST_MODE" != true ]] && read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            5)
                ssl_prompt_general "ssl_logic_check_cert"
                [[ "$TEST_MODE" != true ]] && read -p "$MSG_PRESS_ENTER_CONTINUE"

                ;;
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
