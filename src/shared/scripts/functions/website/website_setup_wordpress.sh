# =====================================
# 🌀 website_setup_wordpress – Install WordPress with provided or auto admin
# =====================================
website_setup_wordpress_logic() {
  local site_name="$1"
  local auto_generate="${2:-true}"

  if [[ -z "$site_name" ]]; then
    echo -e "${RED}${CROSSMARK} Missing site name.${NC}"
    return 1
  fi

  local SITE_DIR="$SITES_DIR/$site_name"
  local ENV_FILE="$SITE_DIR/.env"

  # 📄 Load .env (fallback tìm trong TMP_DIR nếu cần)
  if [[ ! -f "$ENV_FILE" ]]; then
    local tmp_env_path
    tmp_env_path=$(find "$TMP_DIR" -maxdepth 1 -type d -name "${site_name}_*" | head -n 1)
    if [[ -n "$tmp_env_path" && -f "$tmp_env_path/.env" ]]; then
      ENV_FILE="$tmp_env_path/.env"
      SITE_DIR="$tmp_env_path"
    else
      echo -e "${RED}${CROSSMARK} .env file not found for site '$site_name'${NC}"
      return 1
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

  local PHP_CONTAINER="${site_name}-php"
  local DB_CONTAINER="${site_name}-mariadb"
  local SITE_URL="https://$DOMAIN"

  # 🔐 Tạo tài khoản admin
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
    ADMIN_EMAIL="admin@$site_name.local"
  else
    read -p "👤 Enter admin username: " ADMIN_USER
    while [[ -z "$ADMIN_USER" ]]; do
      echo "${WARNING} Cannot be empty."
      read -p "👤 Enter admin username: " ADMIN_USER
    done

    read -s -p "🔐 Enter admin password: " ADMIN_PASSWORD; echo
    read -s -p "🔐 Confirm password: " CONFIRM_PASSWORD; echo
    while [[ "$ADMIN_PASSWORD" != "$CONFIRM_PASSWORD" || -z "$ADMIN_PASSWORD" ]]; do
      echo "${WARNING} Passwords do not match or are empty. Please try again."
      read -s -p "🔐 Enter admin password: " ADMIN_PASSWORD; echo
      read -s -p "🔐 Confirm password: " CONFIRM_PASSWORD; echo
    done

    read -p "📧 Enter admin email (ENTER to use admin@$site_name.local): " ADMIN_EMAIL
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@$site_name.local}"
  fi

  # ✨ Cài WordPress
  echo -e "${BLUE}▹ Starting WordPress installation for '$site_name'...${NC}"
  echo -e "${YELLOW}⏳ Waiting for PHP container '$PHP_CONTAINER' to start...${NC}"
  local timeout=30
  while ! is_container_running "$PHP_CONTAINER"; do
    sleep 1
    ((timeout--))
    if (( timeout <= 0 )); then
      echo -e "${RED}${CROSSMARK} PHP container '$PHP_CONTAINER' not ready after 30s.${NC}"
      return 1
    fi
    echo -ne "⏳ Waiting for PHP container... ($((30-timeout))/30)\r"
  done

  # 📦 Tải WordPress nếu chưa có
  if [[ ! -f "$SITE_DIR/wordpress/index.php" ]]; then
    echo -e "${YELLOW}📦 Downloading WordPress...${NC}"
    docker exec -i "$PHP_CONTAINER" sh -c "mkdir -p /var/www/html && chown -R nobody:nogroup /var/www/html"
    docker exec -i "$PHP_CONTAINER" sh -c "curl -o /var/www/html/wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
      tar -xzf /var/www/html/wordpress.tar.gz --strip-components=1 -C /var/www/html && rm /var/www/html/wordpress.tar.gz"
    echo -e "${GREEN}${CHECKMARK} WordPress source code downloaded.${NC}"
  else
    echo -e "${GREEN}${CHECKMARK} WordPress source code already exists.${NC}"
  fi

  # ⚙️ wp-config
  wp_set_wpconfig "$PHP_CONTAINER" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_CONTAINER"

  # 🚀 Install WP
  wp_install "$PHP_CONTAINER" "$SITE_URL" "$site_name" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

  # 🧑‍🔧 Quyền thư mục
  if is_container_running "$PHP_CONTAINER"; then
    docker exec -u root "$PHP_CONTAINER" chown -R nobody:nogroup "/var/www/" || {
      echo -e "${RED}${CROSSMARK} Permission setting failed.${NC}"
      return 1
    }
  else
    echo -e "${RED}${CROSSMARK} Skipping chown as container is not ready.${NC}"
  fi

  # 🔁 Permalinks
  wp_set_permalinks "$PHP_CONTAINER" "$SITE_URL"
  # wp_plugin_install_performance_lab "$PHP_CONTAINER" # Optional

  echo -e "${YELLOW}${CHECKMARK} WordPress installation completed.${NC}"
  website_print_wp_info "$SITE_URL" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"
}

website_print_wp_info() {
  local site_url="$1"
  local admin_user="$2"
  local admin_password="$3"
  local admin_email="$4"
  
  echo -e "${YELLOW}🌐 Site URL: $site_url${NC}"
  echo -e "${YELLOW}👤 Admin URL: $site_url/wp-admin${NC}"
  echo -e "${YELLOW}👤 Admin User: $admin_user${NC}"
  echo -e "${YELLOW}🔐 Admin Password: $admin_password${NC}"
  echo -e "${YELLOW}📧 Admin Email: $admin_email${NC}"
}
