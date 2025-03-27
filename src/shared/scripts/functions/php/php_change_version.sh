php_change_version() {
  source "$CONFIG_FILE"

  select_website || return 1

  SITE_DIR="$SITES_DIR/$SITE_NAME"
  ENV_FILE="$SITE_DIR/.env"
  DOCKER_COMPOSE_FILE="$SITE_DIR/docker-compose.yml"

  if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}❌ Không tìm thấy file .env trong website ${SITE_NAME}!${NC}"
    return 1
  fi

  php_choose_version || return 1
  selected_php="$REPLY"

  # ✅ Cập nhật .env
  sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$selected_php/" "$ENV_FILE"
  echo -e "${GREEN}✅ Đã cập nhật phiên bản PHP trong .env: $selected_php${NC}"

  # ✅ Cập nhật docker-compose.yml (nếu có)
  if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
    echo -e "${YELLOW}🔧 Đang cập nhật docker-compose.yml với PHP version mới...${NC}"
    sed -i.bak -E "s|^( *image: *bitnami/php-fpm:)[^ ]+|\1${selected_php}|" "$DOCKER_COMPOSE_FILE"
    
    if grep -q "bitnami/php-fpm:$selected_php" "$DOCKER_COMPOSE_FILE"; then
      echo -e "${GREEN}✅ docker-compose.yml đã được cập nhật thành công.${NC}"
    else
      echo -e "${RED}❌ Không tìm thấy dòng image để cập nhật. Vui lòng kiểm tra thủ công.${NC}"
    fi
  else
    echo -e "${RED}❌ Không tìm thấy docker-compose.yml để cập nhật!${NC}"
  fi


  # ✅ Restart container PHP
  echo -e "${YELLOW}🔄 Đang khởi động lại website để áp dụng thay đổi...${NC}"
  cd "$SITE_DIR"
  docker compose stop php
  docker rm -f "${SITE_NAME}-php" 2>/dev/null || true
  docker compose up -d php

  echo -e "${GREEN}✅ Website $SITE_NAME đã chạy lại với PHP: $selected_php${NC}"
}
