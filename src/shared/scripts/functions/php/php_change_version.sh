php_change_version() {
  source "$CONFIG_FILE"

  select_website || return 1

  SITE_DIR="$SITES_DIR/$SITE_NAME"
  ENV_FILE="$SITE_DIR/.env"
  DOCKER_COMPOSE_FILE="$SITE_DIR/docker-compose.yml"

  if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}❌ .env file not found in website ${SITE_NAME}!${NC}"
    return 1
  fi

  php_choose_version || return 1
  selected_php="$REPLY"

  # ✅ Update .env
  sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$selected_php/" "$ENV_FILE"
  echo -e "${GREEN}✅ Updated PHP version in .env: $selected_php${NC}"

  # ✅ Update docker-compose.yml (if exists)
  if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
    echo -e "${YELLOW}🔧 Updating docker-compose.yml with new PHP version...${NC}"
    sed -i.bak -E "s|^( *image: *bitnami/php-fpm:)[^ ]+|\1${selected_php}|" "$DOCKER_COMPOSE_FILE"
    
    if grep -q "bitnami/php-fpm:$selected_php" "$DOCKER_COMPOSE_FILE"; then
      echo -e "${GREEN}✅ docker-compose.yml has been updated successfully.${NC}"
    else
      echo -e "${RED}❌ Image line not found for update. Please check manually.${NC}"
    fi
  else
    echo -e "${RED}❌ docker-compose.yml not found for update!${NC}"
  fi


  # ✅ Restart PHP container
  echo -e "${YELLOW}🔄 Restarting website to apply changes...${NC}"

run_in_dir "$SITE_DIR" docker compose stop php
run_in_dir "$SITE_DIR" docker rm -f "${SITE_NAME}-php" 2>/dev/null || true
run_in_dir "$SITE_DIR" docker compose up -d php

  echo -e "${GREEN}✅ Website $SITE_NAME is now running with PHP: $selected_php${NC}"
}
