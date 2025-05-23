d#!/bin/bash
# ==================================================
# File: website_setup_wordpress.sh
# Description: Functions to set up and install WordPress for a website, including:
#              - Displaying WordPress admin information.
#              - Setting up WordPress with wp-cli, configuring wp-config.php, and installing plugins.
#              - Managing permissions and restarting NGINX.
# Functions:
#   - website_wordpress_print: Display WordPress site admin info.
#       Parameters:
#           $1 - domain: Domain name of the website.
#           $2 - admin_user: Admin username.
#           $3 - admin_password: Admin password.
#           $4 - admin_email: Admin email address.
#   - website_setup_wordpress_logic: Setup and install WordPress for a site.
#       Parameters:
#           $1 - domain: Domain name of the website.
#           $2 - auto_generate (optional): Whether to auto-generate admin credentials (default: true).
# ==================================================

website_wordpress_print() {
  local domain="$1"
  local admin_user="$2"
  local admin_password="$3"
  local admin_email="$4"
  local site_dir="$SITES_DIR/$domain"
  local site_url="https://$domain"

  print_msg info "$INFO_SITE_URL: ${GREEN}$site_url${NC}"
  print_msg info "$INFO_ADMIN_URL: ${GREEN}$site_url/wp-admin${NC}"
  print_msg info "$INFO_ADMIN_USER: ${GREEN}$admin_user${NC}"
  print_msg info "$INFO_ADMIN_PASSWORD: ${GREEN}$admin_password${NC}"
  print_msg info "$INFO_ADMIN_EMAIL: ${GREEN}$admin_email${NC}"
}

website_setup_wordpress_logic() {
  local domain="$1"
  local auto_generate="${2:-true}"

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1
  local db_name db_user db_pass php_container

  # Load variables from .config.json
  db_name=$(json_get_site_value "$domain" "db_name")
  db_user=$(json_get_site_value "$domain" "db_user")
  db_pass=$(json_get_site_value "$domain" "db_pass")
  php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")

  # Create admin account
  local admin_user admin_password admin_email
  if [[ "$TEST_MODE" == true ]]; then
    admin_user="${admin_user:-admin-test}"
    admin_password="${admin_password:-testpass}"
    admin_email="${admin_email:-admin@test.local}"
    website_wordpress_print "$domain" "$admin_user" "$admin_password" "$admin_email"
    return 0
  fi

  if [[ "$auto_generate" == true ]]; then
    admin_user="admin-$(openssl rand -base64 6 | tr -dc 'a-zA-Z0-9' | head -c 8)"
    admin_password=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 16)
    admin_email="admin@$domain"
  else
    # Prompt for admin username
    while true; do
      admin_user=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_USERNAME: " "${TEST_ADMIN_USER:-admin}")
      debug_log "[wordpress] Admin username: $admin_user"
      [[ -n "$admin_user" ]] && break
      print_msg warning "$WARNING_ADMIN_USERNAME_EMPTY"
    done

    # Prompt for admin password
    while true; do
      echo -ne "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD: "
      read -rs admin_password
      echo
      echo -ne "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD_CONFIRM: "
      read -rs confirm_password
      echo

      if [[ -n "$admin_password" && "$admin_password" == "$confirm_password" ]]; then
        break
      fi

      print_msg warning "$WARNING_ADMIN_PASSWORD_MISMATCH"
    done

    # Prompt for admin email
    admin_email=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_EMAIL: " "${TEST_ADMIN_EMAIL:-admin@$domain}")
  fi

  # Check if PHP container is running
  local php_ready_ok=false
  if _is_container_running "$php_container"; then
    php_ready_ok=true
  fi
  if [[ "$php_ready_ok" == false ]]; then
    print_msg error "$ERROR_PHP_CONTAINER_NOT_READY $php_container"
    return 1
  fi

  # Install WordPress
  print_msg step "$INFO_DOWNLOADING_WP"
  if [[ ! -f "$site_dir/wordpress/index.php" ]]; then
    local wp_url="https://wordpress.org/latest.tar.gz"
    if ! network_check_http "$wp_url"; then
      print_msg error "$ERROR_WP_SOURCE_URL_NOT_REACHABLE: $wp_url"
      return 1
    fi

    docker_exec_php "$domain" "chown -R nobody:nogroup /var/www/"
    local wp_download_cmd
    wp_download_cmd="curl -o /var/www/html/wordpress.tar.gz -L $wp_url && \
  tar -xzf /var/www/html/wordpress.tar.gz --strip-components=1 -C /var/www/html && \
  rm /var/www/html/wordpress.tar.gz"

    docker_exec_php "$domain" "$wp_download_cmd" >/dev/null 2>&1
    exit_if_error $? "failed to download WordPress"
    print_msg success "$SUCCESS_WP_SOURCE_DOWNLOADED"
  else
    print_msg success "$SUCCESS_WP_SOURCE_EXISTS"
  fi

  # Configure wp-config
  wp_set_wpconfig "$php_container" "$db_name" "$db_user" "$db_pass" >/dev/null 2>&1

  # Run WordPress installation
  wp_install "$domain" "https://$domain" "$domain" "$admin_user" "$admin_password" "$admin_email" >/dev/null 2>&1

  # Set permissions
  print_msg step "$MSG_WEBSITE_PERMISSIONS: $domain"
  if [[ "$php_ready_ok" == true ]]; then
    run_cmd "docker exec -u root -i $php_container chown -R nobody:nogroup /var/www/"
  else
    print_msg warning "$WARNING_SKIP_CHOWN"
  fi

  # Configure permalinks
  wp_set_permalinks "$domain"
  website_wordpress_print "$domain" "$admin_user" "$admin_password" "$admin_email"
  wp_plugin_install_security_plugin "$domain"
  print_msg completed "$SUCCESS_WP_INSTALL_DONE"

  # Set cache value to `no-cache`
  json_set_site_value "$domain" "cache" "no-cache"

  # Restart NGINX
  nginx_restart
}