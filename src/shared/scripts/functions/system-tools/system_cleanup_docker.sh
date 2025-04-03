system_cleanup_docker_logic() {
  # Check if Docker is installed
  if ! command -v docker &> /dev/null; then
    echo "${CROSSMARK} Docker is not installed. Please install Docker first."
    exit 1
  fi

  # Clean up unused Docker resources
  echo -e "${YELLOW}🧹 Cleaning up unused Docker resources...${NC}"
  docker system prune -af --volumes

  # Check for dangling images and remove them
  #echo -e "${YELLOW}🧹 Removing dangling images...${NC}"
  #docker rmi $(docker images -f "dangling=true" -q) || true

  # Check for stopped containers and remove them
  #echo -e "${YELLOW}🧹 Removing stopped containers...${NC}"
  #docker rm $(docker ps -a -q --filter "status=exited") || true

  # Check for unused networks and remove them
  echo -e "${YELLOW}🧹 Removing unused networks...${NC}"
  docker network prune -f

  echo -e "${GREEN}${CHECKMARK} Docker cleanup completed successfully!${NC}"
}