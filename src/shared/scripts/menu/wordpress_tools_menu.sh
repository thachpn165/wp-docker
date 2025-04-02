# 📌 WordPress Tools Menu
wordpress_tools_menu() {
    echo -e "${BLUE}===== WordPress Tools =====${NC}"
    echo -e "  ${GREEN}[1]${NC} Reset Admin Password"
    echo -e "  ${GREEN}[2]${NC} Edit User Roles"
    echo -e "  ${GREEN}[3]${NC} Enable/Disable Auto-update for All Plugins"
    echo -e "  ${GREEN}[4]${NC} Protect wp-login.php"
    echo ""
    [[ "$TEST_MODE" != true ]] && read -p "Select function (or press Enter to exit): " wp_tool_choice

    case $wp_tool_choice in
        1)
            bash "$MENU_DIR/wordpress/wordpress_reset_admin_passwd_menu.sh"; read -p "Press Enter to continue..."
            ;;
        2)
            bash "$MENU_DIR/wordpress/wordpress_reset_user_role_menu.sh"; read -p "Press Enter to continue..."
            ;;
        3)
            bash "$MENU_DIR/wordpress/wordpress_auto_update_plugin_menu.sh" ; read -p "Press Enter to continue..."
            ;;
        4)
            bash "$MENU_DIR/wordpress/wordpress_protect_wp_login_menu.sh" ; read -p "Press Enter to continue..."
            ;;
        *)
            echo -e "${RED}${CROSSMARK} Invalid option or you have exited.${NC}"
            ;;
    esac
}
