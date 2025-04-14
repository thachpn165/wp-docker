# 📌 WordPress Tools Menu
wordpress_tools_menu() {
    while true; do
        print_msg title "$TITLE_MENU_WORDPRESS"
        print_msg label "${GREEN}[1]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_RESET_ADMPASSWD${NC}"
        print_msg label "${GREEN}[2]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_EDIT_USER_ROLE${NC}"
        print_msg label "${GREEN}[3]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_AUTO_UPDATE_PLUGIN${NC}"
        print_msg label "${GREEN}[4]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_PROTECT_WPLOGIN${NC}"
        print_msg label "${GREEN}[5]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_MIGRATION${NC}"
        print_msg label "${GREEN}[6]${NC} ${STRONG}$MSG_EXIT${NC}"
        echo ""
        read -p "$MSG_SELECT_OPTION " choice

        case $choice in
        1)
            wordpress_prompt_reset_admin_passwd 
            read -p "$MSG_PRESS_ENTER_CONTINUE"
            ;;
        2)
            wordpress_prompt_reset_roles
            read -p "$MSG_PRESS_ENTER_CONTINUE"
            ;;
        3)
            wordpress_prompt_auto_update_plugin
            read -p "$MSG_PRESS_ENTER_CONTINUE"
            ;;
        4)
            wordpress_prompt_protect_wplogin
            read -p "$MSG_PRESS_ENTER_CONTINUE"
            ;;
        5)
            wordpress_prompt_migration
            read -p "$MSG_PRESS_ENTER_CONTINUE"
            ;;
        6)
            break
            ;;
        *)
            #echo -e "${RED}${CROSSMARK} Invalid option or you have exited.${NC}"
            print_msg error "$ERROR_SELECT_OPTION_INVALID"
            ;;
        esac
    done
}
