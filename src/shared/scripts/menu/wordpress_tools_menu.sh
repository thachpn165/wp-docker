# 📌 WordPress Tools Menu
wordpress_tools_menu() {
    echo -e "${BLUE}===== WordPress Tools =====${NC}"
    echo -e "  ${GREEN}[1]${NC} Reset Admin Password"
    echo -e "  ${GREEN}[2]${NC} Edit User Roles"
    echo -e "  ${GREEN}[3]${NC} Enable/Disable Auto-update for All Plugins"
    echo -e "  ${GREEN}[4]${NC} Protect wp-login.php"
    echo -e "  ${GREEN}[5]${NC} Reset WordPress Database (Dangerous)"
    echo -e "  ${GREEN}[6]${NC} Delete All Spam Comments"
    echo -e "  ${GREEN}[7]${NC} Update/Downgrade WordPress Core"
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
            source "$WORDPRESS_TOOLS_DIR/protect-wp-login.sh" ; read -p "Press Enter to continue..."
            ;;
        5)
            source "$WORDPRESS_TOOLS_DIR/reset-wp-database.sh" ; read -p "Press Enter to continue..."
            ;;
        6)
            echo -e "${YELLOW}🚀 Delete All Spam Comments feature not implemented yet.${NC}"
            ;;
        7)
            echo -e "${YELLOW}🚀 Update/Downgrade WordPress Core feature not implemented yet.${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid option or you have exited.${NC}"
            ;;
    esac
}
