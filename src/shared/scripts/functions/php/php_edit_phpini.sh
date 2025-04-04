edit_php_ini() {
  select_website || return
  ini_file="$SITES_DIR/$domain/php/php.ini"

  if [[ ! -f "$ini_file" ]]; then
    echo -e "${RED}${CROSSMARK} File not found: $ini_file${NC}"
    return
  fi

  choose_editor || return

  echo -e "${CYAN}📝 Opening: $ini_file with editor ${EDITOR_CMD}${NC}"
  $EDITOR_CMD "$ini_file"

  echo -e "${YELLOW}🔄 Restarting PHP container to apply changes...${NC}"
  docker compose -f "$SITES_DIR/$domain/docker-compose.yml" restart php
  echo -e "${GREEN}${CHECKMARK} PHP container has been restarted successfully.${NC}"
}
