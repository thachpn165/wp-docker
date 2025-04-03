edit_php_fpm_conf() {
  select_website || return
  conf_file="$SITES_DIR/$domain/php/php-fpm.conf"

  if [[ ! -f "$conf_file" ]]; then
    echo -e "${RED}${CROSSMARK} File not found: $conf_file${NC}"
    return
  fi

  choose_editor || return

  echo -e "${CYAN}📝 Opening: $conf_file with editor ${EDITOR_CMD}${NC}"
  $EDITOR_CMD "$conf_file"

  echo -e "${YELLOW}🔄 Restarting PHP container to apply changes...${NC}"
  docker compose -f "$SITES_DIR/$domain/docker-compose.yml" restart php
  echo -e "${GREEN}${CHECKMARK} PHP container has been restarted successfully.${NC}"
}
