# 🛠️ Manage Docker containers
system_manage_docker_logic() {

    # Check if container_name is provided, if so, process it
    if [ -n "$1" ]; then
        container_name="$1"
        container_action="$2"
        
        # Logic to handle selected action
        if [[ "$container_action" == "1" ]]; then
            docker logs -f $container_name
        elif [[ "$container_action" == "2" ]]; then
            docker restart $container_name
            echo -e "${GREEN}✅ Container has been restarted.${NC}"
        fi
    fi
}