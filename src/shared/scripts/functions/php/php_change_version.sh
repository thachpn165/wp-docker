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
  local site_name="$1"
  local php_version="$2"  # This will be passed from CLI

  # Set paths
  local site_dir="$SITES_DIR/$site_name"
  local env_file="$site_dir/.env"
  local docker_compose_file="$site_dir/docker-compose.yml"

  # Ensure .env exists
  if [[ ! -f "$env_file" ]]; then
    echo -e "${RED}${CROSSMARK} .env file not found for website ${site_name}!${NC}"
    return 1
  fi

  # Check if PHP version was provided
  if [[ -z "$php_version" ]]; then
    echo -e "${RED}${CROSSMARK} No PHP version provided! Please provide a PHP version in the CLI input.${NC}"
    return 1
  fi

  # Update .env file
  echo -e "${YELLOW}🔧 Updating .env with new PHP version...${NC}"
  sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$php_version/" "$env_file"
  echo -e "${GREEN}${CHECKMARK} Updated PHP version in .env: $php_version${NC}"

  # Update docker-compose.yml if it exists
  if [[ -f "$docker_compose_file" ]]; then
    echo -e "${YELLOW}🔧 Updating docker-compose.yml with new PHP version...${NC}"
    sed -i.bak -E "s|^( *image: *bitnami/php-fpm:)[^ ]+|\1${php_version}|" "$docker_compose_file"
    if grep -q "bitnami/php-fpm:$php_version" "$docker_compose_file"; then
      echo -e "${GREEN}${CHECKMARK} docker-compose.yml has been updated successfully.${NC}"
    else
      echo -e "${RED}${CROSSMARK} Image line not found for update. Please check manually.${NC}"
    fi
  else
    echo -e "${RED}${CROSSMARK} docker-compose.yml not found for update!${NC}"
  fi

  # Restart PHP container
  echo -e "${YELLOW}🔄 Restarting PHP container to apply changes...${NC}"
  run_in_dir "$site_dir" docker compose stop php
  run_in_dir "$site_dir" docker rm -f "${site_name}-php" 2>/dev/null || true
  run_in_dir "$site_dir" docker compose up -d php

  echo -e "${GREEN}${CHECKMARK} Website $site_name is now running with PHP: $php_version${NC}"
}