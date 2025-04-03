# 🔁 Rebuild PHP container (does not affect database)
php_rebuild_container_logic() {
  local site_name="$1" 

  # Check if SITE_NAME is set
  if [[ -z "$site_name" ]]; then
    echo -e "${RED}${CROSSMARK} Error: SITE_NAME is not set!${NC}"
    return 1
  fi

  echo -e "${YELLOW}🔁 Restarting PHP container for site: $site_name${NC}"
  
  # Check if the container is running before stopping
  if docker ps -q -f name="$site_name-php" &> /dev/null; then
    docker compose -f "$SITES_DIR/$site_name/docker-compose.yml" stop php
    echo -e "${GREEN}${CHECKMARK} Stopped the PHP container successfully.${NC}"
  else
    echo -e "${YELLOW}${WARNING} PHP container is not running. Skipping stop operation.${NC}"
  fi
  
  # Remove the old PHP container
  docker rm -f "$site_name-php" 2>/dev/null || true
  echo -e "${GREEN}${CHECKMARK} Removed the old PHP container (if it existed).${NC}"

  # Rebuild and restart the PHP container
  if ! docker compose -f "$SITES_DIR/$site_name/docker-compose.yml" up -d php --build; then
    echo -e "${RED}${CROSSMARK} Failed to rebuild the PHP container.${NC}"
    return 1
  fi

  echo -e "${GREEN}${CHECKMARK} PHP container has been rebuilt and restarted successfully.${NC}"
}