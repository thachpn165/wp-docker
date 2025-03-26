edit_php_fpm_conf() {
  select_website || return
  conf_file="$SITES_DIR/$SITE_NAME/php/php-fpm.conf"

  if [[ ! -f "$conf_file" ]]; then
    echo -e "${RED}❌ Không tìm thấy: $conf_file${NC}"
    return
  fi

  choose_editor || return

  echo -e "${CYAN}📝 Đang mở: $conf_file với trình soạn thảo ${EDITOR_CMD}${NC}"
  $EDITOR_CMD "$conf_file"

  echo -e "${YELLOW}🔄 Đang restart container PHP để áp dụng thay đổi...${NC}"
  docker compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" restart php
  echo -e "${GREEN}✅ Đã restart container PHP thành công.${NC}"
}
