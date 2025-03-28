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
    read -p "Select function (or press Enter to exit): " wp_tool_choice

    case $wp_tool_choice in
        1)
            source "$WORDPRESS_TOOLS_DIR/reset-admin-password.sh"
            ;;
        2)
            source "$WORDPRESS_TOOLS_DIR/reset-user-role.sh"
            ;;
        3)
            source "$WORDPRESS_TOOLS_DIR/plugin-auto-update.sh"
            ;;
        4)
            source "$WORDPRESS_TOOLS_DIR/protect-wp-login.sh"
            ;;
        5)
            source "$WORDPRESS_TOOLS_DIR/reset-wp-database.sh"
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
