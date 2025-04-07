php_rebuild_container_logic() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  print_msg step "$(printf "$STEP_WEBSITE_RESTARTING" "$domain")"

  local compose_file="$SITES_DIR/$domain/docker-compose.yml"

  if docker ps -q -f name="$domain-php" &>/dev/null; then
    docker compose -f "$compose_file" stop php
    print_msg success "$SUCCESS_CONTAINER_STOP"
  else
    print_msg warning "$WARNING_PHP_NOT_RUNNING"
  fi

  docker rm -f "$domain-php" 2>/dev/null || true
  print_msg success "$SUCCESS_CONTAINER_OLD_REMOVED"

  if ! docker compose -f "$compose_file" up -d php --build; then
    print_msg error "$ERROR_PHP_REBUILD_FAILED"
    return 1
  fi

  print_msg success "$SUCCESS_WEBSITE_RESTART"
}