# Function: php_change_version_logic
# Description:
#   This function updates the PHP version for a specified website by modifying the `.env` file
#   and the `docker-compose.yml` file in the site's directory. It also restarts the PHP container
#   to apply the changes.
#
# Parameters:
#   1. site_name (string): The name of the site whose PHP version needs to be updated.
#   2. php_version (string): The new PHP version to set (passed from the CLI).
#
# Behavior:
#   - Ensures the `.env` file exists in the site's directory.
#   - Validates that a PHP version is provided.
#   - Updates the `PHP_VERSION` value in the `.env` file.
#   - Updates the PHP image version in the `docker-compose.yml` file if it exists.
#   - Restarts the PHP container to apply the changes.
#
# Outputs:
#   - Displays success or error messages for each step of the process.
#
# Notes:
#   - The function assumes the existence of `$SITES_DIR` as the base directory for sites.
#   - Uses `sed` to perform in-place updates to `.env` and `docker-compose.yml` files.
#   - Relies on the `run_in_dir` function to execute Docker commands in the site's directory.
#
# Exit Codes:
#   - Returns 1 if the `.env` file is missing or if no PHP version is provided.
php_change_version_logic() {
  local domain="$1"
  local php_version="$2"

  local site_dir="$SITES_DIR/$domain"
  local env_file="$site_dir/.env"
  local docker_compose_file="$site_dir/docker-compose.yml"

  if [[ ! -f "$env_file" ]]; then
    print_and_debug error "$ERROR_ENV_NOT_FOUND: $env_file"
    return 1
  fi

  if [[ -z "$php_version" ]]; then
    print_and_debug error "$ERROR_PHP_VERSION_REQUIRED"
    return 1
  fi

  print_msg step "$STEP_PHP_UPDATING_ENV"
  sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$php_version/" "$env_file"
  print_msg success "$(printf "$SUCCESS_PHP_ENV_UPDATED" "$php_version")"

  if [[ -f "$docker_compose_file" ]]; then
    print_msg step "$STEP_PHP_UPDATING_DOCKER_COMPOSE"
    sed -i.bak -E "s|^( *image: *bitnami/php-fpm:)[^ ]+|\1${php_version}|" "$docker_compose_file"
    if grep -q "bitnami/php-fpm:$php_version" "$docker_compose_file"; then
      print_msg success "$SUCCESS_PHP_DOCKER_COMPOSE_UPDATED"
    else
      print_msg warning "$WARNING_PHP_IMAGE_LINE_NOT_FOUND"
    fi
  else
    print_msg error "$ERROR_PHP_DOCKER_COMPOSE_NOT_FOUND"
  fi

  print_msg step "$STEP_PHP_RESTARTING"
  run_in_dir "$site_dir" docker compose stop php
  run_in_dir "$site_dir" docker rm -f "${domain}-php" 2>/dev/null || true
  run_in_dir "$site_dir" docker compose up -d php

  print_msg success "$(printf "$SUCCESS_PHP_CHANGED" "$domain" "$php_version")"
}