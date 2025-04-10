# =====================================
# 🌀 website_wordpress_print
# # Print WordPress site information
# =====================================
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

# =====================================
# 🌀 website_setup_wordpress – Install WordPress with provided or auto-generated admin credentials
# =====================================
website_setup_wordpress_logic() {
  local domain="$1"
  local auto_generate="${2:-true}"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi
  local db_name db_user db_pass php_container db_container

  # 🌍 Load variables from .config.json
  db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
  db_user=$(json_get_site_value "$domain" "MYSQL_USER")
  db_pass=$(json_get_site_value "$domain" "MYSQL_PASSWORD")
  php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
  db_container=$(json_get_site_value "$domain" "CONTAINER_DB")

  # 🔐 Create admin account
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
      admin_password="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)"
      admin_email="admin@$domain"
  else
      # Lấy username người dùng nhập vào, nếu trống sẽ dùng giá trị mặc định
      admin_user=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_USERNAME: " "${TEST_ADMIN_USER:-admin}")
      debug_log "Admin username entered: $admin_user"  # Thêm dòng debug ở đây

      while [[ -z "$admin_user" ]]; do
          print_msg warning "$WARNING_ADMIN_USERNAME_EMPTY"
          admin_user=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_USERNAME: " "${TEST_ADMIN_USER:-admin}")
          debug_log "Admin username entered (again): $admin_user"  # Thêm dòng debug ở đây
      done

      # Lấy password người dùng nhập vào
      admin_password=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD: " "${TEST_ADMIN_PASSWORD:-testpass}")
      confirm_password=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD_CONFIRM: " "${TEST_ADMIN_PASSWORD:-testpass}")

      while [[ "$admin_password" != "$confirm_password" || -z "$admin_password" ]]; do
          print_msg warning "$WARNING_ADMIN_PASSWORD_MISMATCH"
         admin_password=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD: " "${TEST_ADMIN_PASSWORD:-testpass}")
         confirm_password=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD_CONFIRM: " "${TEST_ADMIN_PASSWORD:-testpass}")
      done

      # Lấy email người dùng nhập vào
      admin_email=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_EMAIL: " "${admin_email:-admin@$domain}")
  fi

  # 🐳 Check if PHP container is running
  local php_ready_ok=false
  if is_container_running "$php_container"; then
    php_ready_ok=true
  fi
  if [[ "$php_ready_ok" == false ]]; then
    print_msg error "$ERROR_PHP_CONTAINER_NOT_READY $php_container"
    return 1
  fi

  # ✨ Install WordPress
  print_msg info "$INFO_START_WP_INSTALL $domain"
  print_msg progress "$INFO_WAITING_PHP_CONTAINER $php_container"

  stop_loading

  # 📆 Download WordPress if not already present
  if [[ ! -f "$site_dir/wordpress/index.php" ]]; then
    print_msg step "$INFO_DOWNLOADING_WP"
    docker_exec_php "$domain" "chown -R nobody:nogroup /var/www/"
    debug_log "\n➤ chown -R nobody:nogroup /var/www/: domain=$domain"
    local wp_download_cmd
    wp_download_cmd='curl -o /var/www/html/wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
      tar -xzf /var/www/html/wordpress.tar.gz --strip-components=1 -C /var/www/html && \
      rm /var/www/html/wordpress.tar.gz'

    docker_exec_php "$domain" "$wp_download_cmd"
    exit_if_error $? "failed to download WordPress"
    print_msg success "$SUCCESS_WP_SOURCE_DOWNLOADED"
  else
    print_msg success "$SUCCESS_WP_SOURCE_EXISTS"
  fi

  debug_log "[wp_setup] domain=$domain"
  debug_log "[wp_setup] container=$(php_get_container "$domain")"

  # ⚙️ Configure wp-config
  print_msg step "$STEP_WEBSITE_SETUP_WORDPRESS: $domain"
  wp_set_wpconfig "$php_container" "$db_name" "$db_user" "$db_pass" "$db_container"
  wp_install "$domain" "https://$domain" "$domain" "$admin_user" "$admin_password" "$admin_email"

  print_msg step "$MSG_WEBSITE_PERMISSIONS: $domain"
  if [[ "$php_ready_ok" == true ]]; then
    #docker_exec_php "$domain" "chown -R nobody:nogroup /var/www/"
    run_cmd "docker exec -u root -i $php_container chown -R nobody:nogroup /var/www/"
  else
    print_msg warning "$WARNING_SKIP_CHOWN"
  fi

  # 🔁 Configure permalinks
  print_msg step "$STEP_WEBSITE_SETUP_ESSENTIALS: $domain"
  wp_set_permalinks "$domain"
  website_wordpress_print "$domain" "$admin_user" "$admin_password" "$admin_email"
  print_msg completed "$SUCCESS_WP_INSTALL_DONE"
}