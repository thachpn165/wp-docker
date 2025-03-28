edit_php_ini() {
  select_website || return
  ini_file="$SITES_DIR/$SITE_NAME/php/php.ini"

  if [[ ! -f "$ini_file" ]]; then
    echo -e "${RED}❌ File not found: $ini_file${NC}"
    return
  fi

  choose_editor || return

  echo -e "${CYAN}📝 Opening: $ini_file with editor ${EDITOR_CMD}${NC}"
  $EDITOR_CMD "$ini_file"

  echo -e "${YELLOW}🔄 Restarting PHP container to apply changes...${NC}"
  docker compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" restart php
  echo -e "${GREEN}✅ PHP container has been restarted successfully.${NC}"
}
