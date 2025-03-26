# 🛠️ Quản lý container Docker
system_manage_docker() {
    echo -e "${YELLOW}🚀 Quản lý container Docker...${NC}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    echo ""
    echo -e "${CYAN}Nhập tên container để kiểm tra logs hoặc restart:${NC}"
    read -p "Nhập container_name (hoặc nhấn Enter để bỏ qua): " container_name
    if [ -n "$container_name" ]; then
        echo -e "${YELLOW}📑 Chọn thao tác:"
        echo -e "  ${GREEN}[1]${NC} Xem logs"
        echo -e "  ${GREEN}[2]${NC} Restart container"
        read -p "Chọn thao tác: " container_action
        if [[ "$container_action" == "1" ]]; then
            docker logs -f $container_name
        elif [[ "$container_action" == "2" ]]; then
            docker restart $container_name
            echo -e "${GREEN}✅ Container đã được restart.${NC}"
        fi
    fi
    echo ""
    echo -e "${YELLOW}🔚 Nhấn Enter để quay lại menu...${NC}"
    read -r
}