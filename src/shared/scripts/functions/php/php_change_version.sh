php_change_version_logic() {
  local domain="$1"
  local php_version="$2"

  local site_dir="$SITES_DIR/$domain"
  local docker_compose_file="$site_dir/docker-compose.yml"

  debug_log "[PHP] Changing PHP version for domain: $domain"
  debug_log "[PHP] New version: $php_version"
  debug_log "[PHP] docker-compose path: $docker_compose_file"

  if [[ -z "$php_version" ]]; then
    print_and_debug error "$ERROR_PHP_VERSION_REQUIRED"
    return 1
  fi

  print_msg step "$STEP_PHP_UPDATING_ENV"
  json_set_site_value "$domain" "PHP_VERSION" "$php_version"
  print_msg success "$(printf "$SUCCESS_PHP_ENV_UPDATED" "$php_version")"

  if [[ -f "$docker_compose_file" ]]; then
    print_msg step "$STEP_PHP_UPDATING_DOCKER_COMPOSE"
    # Update PHP version in docker-compose.yml by modifying only the version number
    sedi "s|bitnami/php-fpm:.*|bitnami/php-fpm:$php_version|" "$docker_compose_file"
  else
    print_and_debug error "$ERROR_PHP_DOCKER_COMPOSE_NOT_FOUND"
    return 1
  fi

  # Get container name from .config.json
  local php_container
  php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")

  print_msg step "$STEP_PHP_RESTARTING"
  run_in_dir "$site_dir" docker compose stop php
  run_in_dir "$site_dir" docker rm -f "$php_container" 2>/dev/null || true
  run_in_dir "$site_dir" docker compose up -d php

  print_msg success "$(printf "$SUCCESS_PHP_CHANGED" "$domain" "$php_version")"
}