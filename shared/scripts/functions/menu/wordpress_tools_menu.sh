# 📌 WordPress Tools Menu
wordpress_tools_menu() {
    echo -e "${BLUE}===== WordPress Tools =====${NC}"
    echo -e "  ${GREEN}[1]${NC} Reset mật khẩu Admin"
    echo -e "  ${GREEN}[2]${NC} Sửa quyền thành viên"
    echo -e "  ${GREEN}[3]${NC} Bật/tắt tự cập nhật toàn bộ Plugins"
    echo -e "  ${GREEN}[4]${NC} Bảo vệ wp-login.php"
    echo -e "  ${GREEN}[5]${NC} Reset WordPress Database (Nguy hiểm)"
    echo -e "  ${GREEN}[6]${NC} Import / Export database"
    echo -e "      ${CYAN}[6.1]${NC} Import"
    echo -e "      ${CYAN}[6.2]${NC} Export"
    echo -e "  ${GREEN}[7]${NC} Xoá toàn bộ comment Spam"
    echo -e "  ${GREEN}[8]${NC} Update/Downgrade WordPress core"
    echo ""
    read -p "Chọn chức năng (hoặc nhấn Enter để thoát): " wp_tool_choice

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
            echo -e "${YELLOW}🚀 Chức năng Reset WordPress Database chưa được triển khai.${NC}"
            ;;
        6.1)
            echo -e "${YELLOW}🚀 Chức năng Import database chưa được triển khai.${NC}"
            ;;
        6.2)
            echo -e "${YELLOW}🚀 Chức năng Export database chưa được triển khai.${NC}"
            ;;
        7)
            echo -e "${YELLOW}🚀 Chức năng Xoá toàn bộ comment Spam chưa được triển khai.${NC}"
            ;;
        8)
            echo -e "${YELLOW}🚀 Chức năng Update/Downgrade WordPress core chưa được triển khai.${NC}"
            ;;
        *)
            echo -e "${RED}❌ Lựa chọn không hợp lệ hoặc bạn đã thoát.${NC}"
            ;;
    esac
}
