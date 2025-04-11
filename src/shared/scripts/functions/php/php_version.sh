php_prompt_choose_version() {

  local PHP_VERSION_FILE="$BASE_DIR/php_versions.txt"

  if [[ ! -f "$PHP_VERSION_FILE" ]]; then
    print_msg error "$MSG_NOT_FOUND: $PHP_VERSION_FILE"
    return 1
  fi

  PHP_VERSIONS=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && PHP_VERSIONS+=("$line")
  done <"$PHP_VERSION_FILE"

  if [[ ${#PHP_VERSIONS[@]} -eq 0 ]]; then
    print_msg error "$ERROR_PHP_LIST_EMPTY"
    print_msg tip "wpdocker php get"
    return 1
  fi

  if [[ "$TEST_MODE" == true ]]; then
    REPLY="${TEST_PHP_VERSION:-${PHP_VERSIONS[0]}}"
    debug_log "[TEST_MODE] Selected PHP version: $REPLY"
    return 0
  fi

  print_msg info "$MSG_PHP_LIST_SUPPORTED"
  for i in "${!PHP_VERSIONS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${PHP_VERSIONS[$i]}"
  done

  print_msg recommend "$TIPS_PHP_RECOMMEND_VERSION"
  print_msg warning "$WARNING_PHP_ARM_TITLE"
  print_msg warning "$WARNING_PHP_ARM_LINE1"
  print_msg warning "$WARNING_PHP_ARM_LINE2"
  print_msg warning "$WARNING_PHP_ARM_LINE3"
  print_msg warning "$WARNING_PHP_ARM_LINE4"
  print_msg warning "$WARNING_PHP_ARM_LINE5"

  echo ""
  sleep 0.2
  php_index=$(get_input_or_test_value "$MSG_SELECT_OPTION" "${TEST_PHP_INDEX:-0}")

  if ! [[ "$php_index" =~ ^[0-9]+$ ]] || ((php_index < 0 || php_index >= ${#PHP_VERSIONS[@]})); then
    print_msg error "$ERROR_SELECT_OPTION_INVALID"
    return 1
  fi

  SELECTED_PHP="${PHP_VERSIONS[$php_index]}"

}

php_prompt_change_version() {
  local php_version
  # === Select Website ===
  echo -e "${YELLOW}🔧 Choose the website to change PHP version:${NC}"
  if [[ -z "$domain" ]]; then
    select_website || {
      echo -e "${RED}${CROSSMARK} No website selected.${NC}"
      exit 1
    }
  fi

  # === Prompt for PHP version ===
  echo -e "${YELLOW}🔧 Select PHP version for $domain:${NC}"
  php_prompt_choose_version "$domain"

  # === Handle PHP version change logic ===
  if [[ -n "$SELECTED_PHP" ]]; then
    php_version="$SELECTED_PHP" # Assign the selected PHP version to php_version variable
    echo -e "${GREEN}${CHECKMARK} PHP version for $domain has been updated to $php_version.${NC}"

    # === Send command to CLI ===
    bash "$CLI_DIR/php_change_version.sh" --domain="$domain" --php_version="$php_version"
  else
    echo -e "${RED}${CROSSMARK} Failed to select PHP version for $domain.${NC}"
    exit 1
  fi

  # send command to CLI
  php_cli_change_version --domain="$domain" --php_version="$php_version"
}

php_logic_change_version() {

  local domain="$1"
  local php_version="$2"

  # Check if domain is provided
  if [[ -z "$1" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  local site_dir="$SITES_DIR/$domain"
  local docker_compose_file="$site_dir/docker-compose.yml"

  debug_log "[PHP] Changing PHP version for domain: $domain"
  debug_log "[PHP] New version: $php_version"
  debug_log "[PHP] docker-compose path: $docker_compose_file"

  if [[ -z "$php_version" ]]; then
    php_prompt_change_version
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


