edit_php_ini() {
  select_website || return
  ini_file="$SITES_DIR/$SITE_NAME/php/php.ini"

  if [[ ! -f "$ini_file" ]]; then
    echo -e "${RED}❌ Không tìm thấy: $ini_file${NC}"
    return
  fi

  choose_editor || return

  echo -e "${CYAN}📝 Đang mở: $ini_file với trình soạn thảo ${EDITOR_CMD}${NC}"
  $EDITOR_CMD "$ini_file"

  echo -e "${YELLOW}🔄 Đang restart container PHP để áp dụng thay đổi...${NC}"
  docker compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" restart php
  echo -e "${GREEN}✅ Đã restart container PHP thành công.${NC}"
}
