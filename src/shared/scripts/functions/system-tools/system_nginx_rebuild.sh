system_nginx_rebuild() {
  echo -e "${BLUE}===== Rebuilding NGINX =====${NC}"

  # Stop and remove old NGINX container
  echo -e "${YELLOW}🔄 Stopping and removing old NGINX container...${NC}"
  run_in_dir "$NGINX_PROXY_DIR" docker stop "$NGINX_PROXY_CONTAINER" && docker rm "$NGINX_PROXY_CONTAINER"

  # Get image name from docker-compose.yml
  IMAGE_NAME=$(grep -A 10 "$NGINX_PROXY_CONTAINER:" "$NGINX_PROXY_DIR/docker-compose.yml" | grep 'image:' | awk '{print $2}' | head -n 1)
  if [[ -z "$IMAGE_NAME" ]]; then
    echo -e "${RED}❌ Could not find image name in docker-compose.yml${NC}"
    return 1
  fi

  # Pull latest image
  echo -e "${YELLOW}🔄 Pulling latest image: $IMAGE_NAME...${NC}"
  run_in_dir "$NGINX_PROXY_DIR" docker pull "$IMAGE_NAME"

  # Start NGINX container
  echo -e "${YELLOW}🔄 Starting NGINX container...${NC}"
  run_in_dir "$NGINX_PROXY_DIR" docker-compose up -d nginx-proxy

  # Check if NGINX container is running
  echo -e "${YELLOW}⏳ Checking if NGINX container is running...${NC}"
  for i in {1..30}; do
    if is_container_running "$NGINX_PROXY_CONTAINER"; then
      echo -e "${GREEN}✅ NGINX container is running.${NC}"
      break
    fi
    sleep 1
  done

  if ! is_container_running "$NGINX_PROXY_CONTAINER"; then
    echo -e "${RED}❌ NGINX container failed to start after 30 seconds.${NC}"
    return 1
  fi

  echo -e "${GREEN}✅ NGINX rebuild successful.${NC}"
}
