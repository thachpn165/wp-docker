#!/bin/bash
# ==================================================
# File: php_rebuild_container.sh
# Description: Functions to rebuild PHP containers for WordPress sites, including prompting 
#              the user to rebuild and executing the rebuild process using Docker Compose.
# Functions:
#   - php_prompt_rebuild_container: Prompt the user to rebuild the PHP container for a selected site.
#       Parameters: None.
#   - php_rebuild_container_logic: Logic to rebuild the PHP container for a given domain.
#       Parameters:
#           $1 - domain: The domain name of the website to rebuild the PHP container for.
# ==================================================

php_prompt_rebuild_container() {
  safe_source "$CLI_DIR/php_rebuild_container.sh"
  local domain

  if ! website_get_selected domain; then
    return 1
  fi
  _is_valid_domain "$domain" || return 1

  # Confirm rebuild of PHP container
  echo -e "${YELLOW}🔁 Rebuild the PHP container for site: $domain${NC}"
  read -p "Are you sure you want to rebuild the PHP container for this site? (y/n): " confirm_rebuild
  confirm_rebuild=$(echo "$confirm_rebuild" | tr '[:upper:]' '[:lower:]')

  if [[ "$confirm_rebuild" != "y" ]]; then
    echo -e "${RED}${CROSSMARK} Operation canceled. No changes made.${NC}"
    exit 1
  fi

  # Call CLI command to rebuild PHP container
  debug_log "[php_prompt_rebuild_container] Rebuilding PHP container for domain: $domain"
  php_cli_rebuild_container --domain="$domain"
}

php_rebuild_container_logic() {
  local domain="$1"
  local compose_file="$SITES_DIR/$domain/docker-compose.yml"
  local php_container

  php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
  print_msg step "$(printf "$STEP_WEBSITE_RESTARTING" "$domain")"

  # Stop PHP container if running
  if docker ps -q -f name="$php_container" &>/dev/null; then
    docker compose -f "$compose_file" stop php
    print_msg success "$SUCCESS_CONTAINER_STOP"
  else
    print_msg warning "$WARNING_PHP_NOT_RUNNING"
  fi

  # Remove old PHP container
  docker rm -f "$php_container" 2>/dev/null || true
  print_msg success "$SUCCESS_CONTAINER_OLD_REMOVED"

  # Rebuild and start PHP container
  if ! docker compose -f "$compose_file" up -d php --build; then
    print_msg error "$ERROR_PHP_REBUILD_FAILED"
    return 1
  fi

  print_msg success "$SUCCESS_WEBSITE_RESTART"
}