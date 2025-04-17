# =====================================
# php_prompt_choose_version: Prompt user to choose a PHP version from cached list
# Requires:
#   - php_versions.txt must exist
#   - TEST_MODE and TEST_PHP_VERSION for testing scenarios
# Outputs:
#   - Sets global variable SELECTED_PHP
# =====================================
php_prompt_choose_version() {

  local PHP_VERSION_FILE="$BASE_DIR/php_versions.txt"

  # Check if the PHP version list file exists
  if [[ ! -f "$PHP_VERSION_FILE" ]]; then
    print_msg error "$MSG_NOT_FOUND: $PHP_VERSION_FILE"
    return 1
  fi

  # Read PHP versions into an array
  PHP_VERSIONS=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && PHP_VERSIONS+=("$line")
  done <"$PHP_VERSION_FILE"

  # If no versions available, show error and suggest update
  if [[ ${#PHP_VERSIONS[@]} -eq 0 ]]; then
    print_msg error "$ERROR_PHP_LIST_EMPTY"
    print_msg tip "wpdocker php get"
    return 1
  fi

  # If in test mode, auto select version
  if [[ "$TEST_MODE" == true ]]; then
    REPLY="${TEST_PHP_VERSION:-${PHP_VERSIONS[0]}}"
    debug_log "[TEST_MODE] Selected PHP version: $REPLY"
    return 0
  fi

  # Display PHP version list
  print_msg info "$MSG_PHP_LIST_SUPPORTED"
  for i in "${!PHP_VERSIONS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${PHP_VERSIONS[$i]}"
  done

  # Display tips and warnings for ARM devices
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

  # Validate selection index
  if ! [[ "$php_index" =~ ^[0-9]+$ ]] || ((php_index < 0 || php_index >= ${#PHP_VERSIONS[@]})); then
    print_msg error "$ERROR_SELECT_OPTION_INVALID"
    return 1
  fi

  # Save selected PHP version
  SELECTED_PHP="${PHP_VERSIONS[$php_index]}"
}

# =====================================
# php_prompt_change_version: Prompt user to change PHP version of a selected site
# Requires:
#   - select_website to choose domain
#   - php_prompt_choose_version to select version
# Calls CLI to perform actual change
# =====================================
php_prompt_change_version() {
  local php_version
  local domain

  # === Chọn website ===
  website_get_selected domain
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  # === Prompt chọn phiên bản PHP ===
  print_msg step "$STEP_PHP_SELECT_VERSION_FOR_DOMAIN: $domain"
  php_prompt_choose_version "$domain"

  # === Nếu không chọn version, thì dừng tại đây ===
  if [[ -z "$SELECTED_PHP" ]]; then
    print_msg warning "$WARNING_PHP_NO_VERSION_SELECTED"
    return 1
  fi

  # === Nếu có chọn, xử lý thay đổi ===
  php_version="$SELECTED_PHP"
  print_msg success "$SUCCESS_PHP_VERSION_SELECTED: $php_version"

  php_cli_change_version --domain="$domain" --php_version="$php_version"
}

# =====================================
# php_logic_change_version: Core logic to update PHP version for a website
# Parameters:
#   $1 - domain: The website domain
#   $2 - php_version: The new PHP version to set
# Requires:
#   - json_set_site_value to update config
#   - docker-compose.yml must exist for the site
#   - sed or sedi to update image tag
# =====================================
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

  # Prompt for PHP version if missing
  if [[ -z "$php_version" ]]; then
    php_prompt_change_version
    return 1
  fi

  # Update PHP version in .config.json
  print_msg step "$STEP_PHP_UPDATING_ENV"
  json_set_site_value "$domain" "PHP_VERSION" "$php_version"
  FORMATTED_SUCCESS_PHP_ENV_UPDATED=$(printf "$SUCCESS_PHP_ENV_UPDATED" "$php_version")
  print_msg success "$FORMATTED_SUCCESS_PHP_ENV_UPDATED"

  # Modify docker-compose.yml to update PHP image version
  if [[ -f "$docker_compose_file" ]]; then
    print_msg step "$STEP_PHP_UPDATING_DOCKER_COMPOSE"
    sedi "s|bitnami/php-fpm:.*|bitnami/php-fpm:$php_version|" "$docker_compose_file"
  else
    print_and_debug error "$ERROR_PHP_DOCKER_COMPOSE_NOT_FOUND"
    return 1
  fi

  # Restart PHP container with new version
  local php_container
  php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")

  print_msg step "$STEP_PHP_RESTARTING"
  run_in_dir "$site_dir" docker compose stop php
  run_in_dir "$site_dir" docker rm -f "$php_container" 2>/dev/null || true
  run_in_dir "$site_dir" docker compose up -d php

  print_msg success "$(printf "$SUCCESS_PHP_CHANGED" "$domain" "$php_version")"
  docker_exec_php "$domain" "php -v"
}