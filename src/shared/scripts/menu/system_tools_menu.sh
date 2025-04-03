#!/bin/bash
source "$FUNCTIONS_DIR/system_loader.sh"
system_tools_menu() {
    echo -e "${BLUE}===== System Tools =====${NC}"
    echo -e "  ${GREEN}[1]${NC} Check System Resources"
    echo -e "  ${GREEN}[2]${NC} Manage Docker Containers"
    echo -e "  ${GREEN}[3]${NC} Cleanup Docker System"
    echo -e "  ${GREEN}[4]${NC} Rebuild NGINX"
    echo ""
    [[ "$TEST_MODE" != true ]] && read -p "Select function (or press Enter to exit): " sys_tool_choice

    case $sys_tool_choice in
        1)
            bash "$MENU_DIR/system-tools/system_check_resources_menu.sh"
            ;;
        2)
            bash "$MENU_DIR/system-tools/system_manage_docker_menu.sh"
            ;;
        3)
            bash "$CLI_DIR/cli/system_cleanup_docker.sh"
            ;;
        4)
            bash "$CLI_DIR1/system_nginx_rebuild.sh"
            ;;
        *)
            echo -e "${RED}${CROSSMARK} Invalid option or you have exited.${NC}"
            ;;
    esac
}