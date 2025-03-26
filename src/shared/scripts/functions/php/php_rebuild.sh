# 🔁 Rebuild container PHP (không ảnh hưởng database)
rebuild_php_container() {
  select_website || return
  echo -e "${YELLOW}🔁 Đang khởi động lại container PHP cho site: $SITE_NAME${NC}"
  docker compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" stop php
  docker rm -f "$SITE_NAME-php" 2>/dev/null || true
  docker compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" up -d php --build
  echo -e "${GREEN}✅ Đã rebuild container PHP thành công.${NC}"
}