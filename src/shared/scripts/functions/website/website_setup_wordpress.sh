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

  local SITE_DIR="$SITES_DIR/$domain"
  local ENV_FILE="$SITE_DIR/.env"

  # 📄 Load .env (fallback to TMP_DIR if necessary)
  if [[ ! -f "$ENV_FILE" ]]; then
    debug_log "ENV file not found at $ENV_FILE. Attempting to find fallback path in TMP_DIR..."

    local tmp_env_path
    tmp_env_path=$(find "$TMP_DIR" -maxdepth 1 -type d -name "${domain}_*" | head -n 1)

    debug_log "Fallback search result: $tmp_env_path"

    if [[ -n "$tmp_env_path" && -f "$tmp_env_path/.env" ]]; then
      ENV_FILE="$tmp_env_path/.env"
      SITE_DIR="$tmp_env_path"
      debug_log "Using fallback ENV file: $ENV_FILE"
    else
      print_and_debug error "$MSG_NOT_FOUND .env: $domain"
      exit 1
    fi
  fi

  local ENV_FILE_DIR
  ENV_FILE_DIR=$(dirname "$ENV_FILE")

  # 🌍 Load variables
  local DOMAIN DB_NAME DB_USER DB_PASS PHP_VERSION
  DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
  DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
  DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
  DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")
  PHP_VERSION=$(fetch_env_variable "$ENV_FILE" "PHP_VERSION")

  PHP_CONTAINER=$(fetch_env_variable "$ENV_FILE" "CONTAINER_PHP")
  DB_CONTAINER=$(fetch_env_variable "$ENV_FILE" "CONTAINER_DB")
  local SITE_URL="https://$DOMAIN"

  # 🔐 Create admin account
  local ADMIN_USER ADMIN_PASSWORD ADMIN_EMAIL
  if [[ "$TEST_MODE" == true ]]; then
    ADMIN_USER="${admin_user:-admin-test}"
    ADMIN_PASSWORD="${admin_password:-testpass}"
    ADMIN_EMAIL="${admin_email:-admin@test.local}"
    website_print_wp_info "$SITE_URL" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"
    return 0
  fi

  if [[ "$auto_generate" == true ]]; then
    ADMIN_USER="admin-$(openssl rand -base64 6 | tr -dc 'a-zA-Z0-9' | head -c 8)"
    ADMIN_PASSWORD="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)"
    ADMIN_EMAIL="admin@$domain.local"
  else
    ADMIN_USER=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_USERNAME: " "${TEST_ADMIN_USER:-admin}")
    while [[ -z "$ADMIN_USER" ]]; do
      print_msg warning "$WARNING_ADMIN_USERNAME_EMPTY"
      ADMIN_USER=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_USERNAME: " "${TEST_ADMIN_USER:-admin}")
    done

    ADMIN_PASSWORD=$(get_input_or_test_value_secret "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD: " "${TEST_ADMIN_PASSWORD:-testpass}")
    CONFIRM_PASSWORD=$(get_input_or_test_value_secret "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD_CONFIRM: " "${TEST_ADMIN_PASSWORD:-testpass}")
    while [[ "$ADMIN_PASSWORD" != "$CONFIRM_PASSWORD" || -z "$ADMIN_PASSWORD" ]]; do
      print_msg warning "$WARNING_ADMIN_PASSWORD_MISMATCH"
      ADMIN_PASSWORD=$(get_input_or_test_value_secret "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD: " "${TEST_ADMIN_PASSWORD:-testpass}")
      CONFIRM_PASSWORD=$(get_input_or_test_value_secret "$PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD_CONFIRM: " "${TEST_ADMIN_PASSWORD:-testpass}")
    done

    #get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_EMAIL" ADMIN_EMAIL
    ADMIN_EMAIL=$(get_input_or_test_value "$PROMPT_WEBSITE_SETUP_WORDPRESS_EMAIL" "${ADMIN_EMAIL:-admin@$domain}")
  fi

  # 🐳 Check if PHP container is running
  local php_ready_ok
  if is_container_running "$PHP_CONTAINER"; then
    php_ready_ok=true
  else
    php_ready_ok=false
  fi
  if [[ "$php_ready_ok" == false ]]; then
    print_msg error "$ERROR_PHP_CONTAINER_NOT_READY $PHP_CONTAINER"
    return 1
  fi

  # ✨ Install WordPress
  print_msg info "$INFO_START_WP_INSTALL $domain"
  print_msg progress "$INFO_WAITING_PHP_CONTAINER $PHP_CONTAINER"

  if [[ "$php_ready_ok" == false ]]; then
    stop_loading
    print_msg error "$ERROR_PHP_CONTAINER_NOT_READY $PHP_CONTAINER"
    return 1
  fi

  stop_loading

  # 📆 Download WordPress if not already present
  if [[ ! -f "$SITE_DIR/wordpress/index.php" ]]; then
    print_msg step "$INFO_DOWNLOADING_WP"
    docker_exec_php "chown -R nobody:nogroup /var/www/"
    wp_download_cmd='curl -o /var/www/html/wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
      tar -xzf /var/www/html/wordpress.tar.gz --strip-components=1 -C /var/www/html && \
      rm /var/www/html/wordpress.tar.gz'

    docker_exec_php "$wp_download_cmd"
    exit_if_error $? "failed to download WordPress"
    print_msg success "$SUCCESS_WP_SOURCE_DOWNLOADED"
  else
    print_msg success "$SUCCESS_WP_SOURCE_EXISTS"
  fi

  # ⚙️ Configure wp-config
  print_msg step "$STEP_WEBSITE_SETUP_WORDPRESS: $domain"
  wp_set_wpconfig "$PHP_CONTAINER" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_CONTAINER"
  wp_install "$PHP_CONTAINER" "$SITE_URL" "$domain" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

  print_msg step "$MSG_WEBSITE_PERMISSIONS: $domain"
  if [[ "$php_ready_ok" == true ]]; then
    docker_exec_php "chown -R nobody:nogroup /var/www/"
  else
    print_msg warning "$WARNING_SKIP_CHOWN"
  fi

  # 🔁 Configure permalinks
  print_msg step "$STEP_WEBSITE_SETUP_ESSENTIALS: $domain"
  wp_set_permalinks "$PHP_CONTAINER" "$SITE_URL"
  website_print_wp_info "$SITE_URL" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"
  print_msg completed "$SUCCESS_WP_INSTALL_DONE"
}

website_print_wp_info() {
  local site_url="$1"
  local admin_user="$2"
  local admin_password="$3"
  local admin_email="$4"

  print_msg info "$INFO_SITE_URL: ${GREEN}$site_url${NC}"
  print_msg info "$INFO_ADMIN_URL: ${GREEN}$site_url/wp-admin${NC}"
  print_msg info "$INFO_ADMIN_USER: ${GREEN}$admin_user${NC}"
  print_msg info "$INFO_ADMIN_PASSWORD: ${GREEN}$admin_password${NC}"
  print_msg info "$INFO_ADMIN_EMAIL: ${GREEN}$admin_email${NC}"
}