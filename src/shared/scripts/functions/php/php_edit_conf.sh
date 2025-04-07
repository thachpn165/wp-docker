# Function: edit_php_fpm_conf
# Description:
#   This function allows the user to edit the PHP-FPM configuration file for a selected website.
#   It verifies the existence of the configuration file, opens it in the user's chosen editor,
#   and restarts the PHP service in the corresponding Docker container.
#
# Globals:
#   SITES_DIR - The base directory containing site configurations.
#   domain - The domain name of the selected website (set by select_website function).
#   EDITOR_CMD - The command for the user's preferred text editor (set by choose_editor function).
#   MSG_NOT_FOUND - Error message for missing files.
#   STEP_WEBSITE_RESTARTING - Message indicating the website is restarting.
#   SUCCESS_WEBSITE_RESTART - Success message for website restart.
#   ERROR_DOCKER_NGINX_RESTART - Error message for Docker restart failure.
#
# Dependencies:
#   - select_website: Prompts the user to select a website and sets the 'domain' variable.
#   - choose_editor: Prompts the user to select a text editor and sets the 'EDITOR_CMD' variable.
#   - print_msg: Prints messages to the console (info, error, step, success).
#   - debug_log: Logs debug information.
#   - docker compose: Used to restart the PHP service in the Docker container.
#
# Arguments:
#   None
#
# Returns:
#   0 - On success.
#   1 - If the configuration file is not found or an error occurs.
#
# Usage:
#   edit_php_fpm_conf
edit_php_fpm_conf() {
  select_website || return
  conf_file="$SITES_DIR/$domain/php/php-fpm.conf"

  if [[ ! -f "$conf_file" ]]; then
    print_msg error "$MSG_NOT_FOUND: $conf_file"
    return 1
  fi

  choose_editor || return

  print_msg info "📝 Opening: $conf_file with editor $EDITOR_CMD"
  debug_log "[PHP FPM CONF] Editing file: $conf_file"
  $EDITOR_CMD "$conf_file"

  print_msg step "$STEP_WEBSITE_RESTARTING"
  docker compose -f "$SITES_DIR/$domain/docker-compose.yml" restart php

  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_WEBSITE_RESTART"
  else
    print_msg error "$ERROR_DOCKER_NGINX_RESTART"
  fi
}