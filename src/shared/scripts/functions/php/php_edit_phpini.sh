edit_php_ini() {
  select_website || return
  ini_file="$SITES_DIR/$domain/php/php.ini"

  if [[ ! -f "$ini_file" ]]; then
    print_msg error "$MSG_NOT_FOUND: $ini_file"
    return 1
  fi

  choose_editor || return

  print_msg info "📝 Opening: $ini_file with editor $EDITOR_CMD"
  debug_log "[PHP INI] Editing file: $ini_file"
  $EDITOR_CMD "$ini_file"

  print_msg step "$STEP_WEBSITE_RESTARTING"
  docker compose -f "$SITES_DIR/$domain/docker-compose.yml" restart php

  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_WEBSITE_RESTART"
  else
    print_msg error "$ERROR_DOCKER_NGINX_RESTART"
  fi
}