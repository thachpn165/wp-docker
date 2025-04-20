# =====================================
# edit_php_fpm_conf: Open and edit the php-fpm.conf file for the selected site
# Requires:
#   - select_website to choose domain
#   - choose_editor to define $EDITOR_CMD
#   - $SITES_DIR and $domain must be properly set
# =====================================
edit_php_fpm_conf() {
  local domain
  website_get_selected domain
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_SITE_NOT_SELECTED"
    return 1
  fi
  _is_valid_domain "$domain" || return 1
  conf_file="$SITES_DIR/$domain/php/php-fpm.conf"

  # Check if the php-fpm.conf file exists
  if [[ ! -f "$conf_file" ]]; then
    print_msg error "$MSG_NOT_FOUND: $conf_file"
    return 1
  fi

  # Let user choose an editor
  choose_editor || return

  # Open the configuration file using the selected editor
  print_msg info "📝 Opening: $conf_file with editor $EDITOR_CMD"
  debug_log "[PHP FPM CONF] Editing file: $conf_file"
  $EDITOR_CMD "$conf_file"

  # Restart PHP service after editing
  print_msg step "$STEP_WEBSITE_RESTARTING"
  docker compose -f "$SITES_DIR/$domain/docker-compose.yml" restart php

  # Check restart result
  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_WEBSITE_RESTART"
  else
    print_msg error "$ERROR_DOCKER_NGINX_RESTART"
  fi
}