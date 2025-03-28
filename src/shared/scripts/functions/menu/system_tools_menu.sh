source "$SYSTEM_TOOLS_FUNC_DIR/system-check-resources.sh"
source "$SYSTEM_TOOLS_FUNC_DIR/system_manage_docker.sh"
source "$SYSTEM_TOOLS_FUNC_DIR/system_cleanup_docker.sh"
source "$SYSTEM_TOOLS_FUNC_DIR/system_nginx_rebuild.sh"

system_tools_menu() {
    echo -e "${BLUE}===== Công Cụ Hệ Thống =====${NC}"
    echo -e "  ${GREEN}[1]${NC} Kiểm tra tài nguyên hệ thống"
    echo -e "  ${GREEN}[2]${NC} Quản lý container Docker"
    echo -e "  ${GREEN}[3]${NC} Dọn dẹp hệ thống Docker"
    echo -e "  ${GREEN}[4]${NC} Rebuild NGINX"
    echo ""
    read -p "Chọn chức năng (hoặc nhấn Enter để thoát): " sys_tool_choice

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
            echo -e "${RED}❌ Lựa chọn không hợp lệ hoặc bạn đã thoát.${NC}"
            ;;
    esac
}