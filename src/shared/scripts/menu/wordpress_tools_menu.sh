# 📌 WordPress Tools Menu
wordpress_tools_menu() {
    print_msg title "$TITLE_MENU_WORDPRESS"
    print_msg label "${GREEN}[1]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_RESET_ADMPASSWD${NC}"
    print_msg label "${GREEN}[2]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_EDIT_USER_ROLE${NC}"
    print_msg label "${GREEN}[3]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_AUTO_UPDATE_PLUGIN${NC}"
    print_msg label "${GREEN}[4]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_PROTECT_WPLOGIN${NC}"
    print_msg label "${GREEN}[5]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_MIGRATION${NC}"
    print_msg label "${GREEN}[6]${NC} ${STRONG}$MSG_EXIT${NC}"
    echo ""
    read -p "$MSG_SELECT_OPTION " choice

    while true; do
        case $choice in
            1)
                bash "$MENU_DIR/wordpress/wordpress_reset_admin_passwd_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            2)
                bash "$MENU_DIR/wordpress/wordpress_reset_user_role_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            3)
                bash "$MENU_DIR/wordpress/wordpress_auto_update_plugin_menu.sh" ; read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            4)
                bash "$MENU_DIR/wordpress/wordpress_protect_wp_login_menu.sh" ; read -p "$MSG_PRESS_ENTER_CONTINUE"
                ;;
            5) 
                bash "$MENU_DIR/wordpress/wordpress_migration_menu.sh" ; read -p "$MSG_PRESS_ENTER_CONTINUE"
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
