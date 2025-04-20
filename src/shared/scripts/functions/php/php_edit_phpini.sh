# =====================================
# edit_php_ini: Open and edit the php.ini file for the selected site
# Requires:
#   - select_website to set $domain
#   - choose_editor to define $EDITOR_CMD
#   - $SITES_DIR and $domain must be properly set
# =====================================
edit_php_ini() {
  local domain

  if ! website_get_selected domain; then
    return 1
  fi
  _is_valid_domain "$domain" || return 1
  ini_file="$SITES_DIR/$domain/php/php.ini"

  # Check if the php.ini file exists
  if [[ ! -f "$ini_file" ]]; then
    print_msg error "$MSG_NOT_FOUND: $ini_file"
    return 1
  fi

  # Prompt user to choose an editor
  choose_editor || return

  # Open the ini file using the selected editor
  print_msg info "📝 Opening: $ini_file with editor $EDITOR_CMD"
  debug_log "[PHP INI] Editing file: $ini_file"
  $EDITOR_CMD "$ini_file"

  # Restart PHP service after editing
  print_msg step "$STEP_WEBSITE_RESTARTING"
  docker compose -f "$SITES_DIR/$domain/docker-compose.yml" restart php

  # Check if restart was successful
  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_WEBSITE_RESTART"
  else
    print_msg error "$ERROR_DOCKER_NGINX_RESTART"
  fi
}
