source "$SYSTEM_TOOLS_FUNC_DIR/system-check-resources.sh"
source "$SYSTEM_TOOLS_FUNC_DIR/system_manage_docker.sh"
source "$SYSTEM_TOOLS_FUNC_DIR/system_cleanup_docker.sh"
source "$SYSTEM_TOOLS_FUNC_DIR/system_nginx_rebuild.sh"

system_tools_menu() {
    echo -e "${BLUE}===== System Tools =====${NC}"
    echo -e "  ${GREEN}[1]${NC} Check System Resources"
    echo -e "  ${GREEN}[2]${NC} Manage Docker Containers"
    echo -e "  ${GREEN}[3]${NC} Cleanup Docker System"
    echo -e "  ${GREEN}[4]${NC} Rebuild NGINX"
    echo ""
    read -p "Select function (or press Enter to exit): " sys_tool_choice

    case $sys_tool_choice in
        1)
            system_check_resources
            ;;
        2)
            system_manage_docker
            ;;
        3)
            system_cleanup_docker
            ;;
        4)
            system_nginx_rebuild
            ;;
        *)
            echo -e "${RED}❌ Invalid option or you have exited.${NC}"
            ;;
    esac
}