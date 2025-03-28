# 🛠️ Manage Docker containers
system_manage_docker() {
    echo -e "${YELLOW}🚀 Managing Docker containers...${NC}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    echo ""
    echo -e "${CYAN}Enter container name to check logs or restart:${NC}"
    read -p "Enter container_name (or press Enter to skip): " container_name
    if [ -n "$container_name" ]; then
        echo -e "${YELLOW}📑 Select operation:"
        echo -e "  ${GREEN}[1]${NC} View logs"
        echo -e "  ${GREEN}[2]${NC} Restart container"
        read -p "Select operation: " container_action
        if [[ "$container_action" == "1" ]]; then
            docker logs -f $container_name
        elif [[ "$container_action" == "2" ]]; then
            docker restart $container_name
            echo -e "${GREEN}✅ Container has been restarted.${NC}"
        fi
    fi
    echo ""
    echo -e "${YELLOW}🔚 Press Enter to return to menu...${NC}"
    read -r
}