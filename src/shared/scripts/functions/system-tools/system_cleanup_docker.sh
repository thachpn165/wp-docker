# 🛠️ Clean up Docker system
system_cleanup_docker() {
    echo -e "${YELLOW}🗑️ Cleaning up Docker system...${NC}"
    docker system prune -a -f
    docker volume prune -f
    echo -e "${GREEN}✅ Cleanup completed.${NC}"
    echo ""
    echo -e "${YELLOW}🔚 Press Enter to return to menu...${NC}"
    read -r
}
