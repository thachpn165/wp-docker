# 🛠️ Dọn dẹp hệ thống Docker
system_cleanup_docker() {
    echo -e "${YELLOW}🗑️ Đang dọn dẹp hệ thống Docker...${NC}"
    docker system prune -a -f
    docker volume prune -f
    echo -e "${GREEN}✅ Dọn dẹp hoàn tất.${NC}"
    echo ""
    echo -e "${YELLOW}🔚 Nhấn Enter để quay lại menu...${NC}"
    read -r
}
