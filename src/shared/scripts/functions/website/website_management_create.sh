# =====================================
# 🐋 website_management_create – Create New WordPress Website
# =====================================
website_management_create() {
  source "$FUNCTIONS_DIR/website/website_create_env.sh"

  echo -e "${BLUE}===== CREATE NEW WORDPRESS WEBSITE =====${NC}"

  # 📥 Input domain and site name
  domain="$(get_input_or_test_value "Domain name (e.g., example.com): " "${TEST_DOMAIN:-example.com}")"
  suggested_site_name=$(echo "$domain" | sed -E 's/\.[a-zA-Z]+$//')
  site_name="$(get_input_or_test_value "Site name (default: $suggested_site_name): " "${TEST_SITE_NAME:-$suggested_site_name}")"
  site_name=${site_name:-$suggested_site_name}

  # Check PHP version
  php_choose_version || return 1
  php_version="$REPLY"

  SITE_DIR="$SITES_DIR/$site_name"
  CONTAINER_PHP="${site_name}-php"
  CONTAINER_DB="${site_name}-mariadb"

  # ❌ Check if site already exists
  if is_directory_exist "$SITE_DIR" false; then
    echo -e "${RED}❌ Website '$site_name' already exists.${NC}"
    return 1
  fi

  # 📝 Create log
  mkdir -p "$LOGS_DIR"
  LOG_FILE="$LOGS_DIR/${site_name}-setup.log"
  touch "$LOG_FILE"
  run_unless_test bash -c "exec > >(tee -a \"$LOG_FILE\") 2>&1"
  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] STARTING SITE CREATION: $site_name =====" >> "$LOG_FILE"

  # 🧱 Create directory structure
  mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
  touch "$SITE_DIR/logs/access.log" "$SITE_DIR/logs/error.log"
  chmod 666 "$SITE_DIR/logs/"*.log

  # 🔧 Configure NGINX
  if ! update_nginx_override_mounts "$site_name"; then
    echo -e "${RED}❌ Unable to update NGINX configuration.${NC}"
    return 1
  fi
  export site_name domain php_version
  run_unless_test bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh" || return 1

  # ⚙️ Create configurations
  copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini" || return 1
  apply_mariadb_config "$SITE_DIR/mariadb/conf.d/custom.cnf" || return 1
  create_optimized_php_fpm_config "$SITE_DIR/php/php-fpm.conf" || return 1
  website_create_env "$SITE_DIR" "$site_name" "$domain" "$php_version" || return 1

  # 🛠️ Create docker-compose.yml
  TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
  TARGET_FILE="$SITE_DIR/docker-compose.yml"
  if is_file_exist "$TEMPLATE_FILE"; then
    set -o allexport && source "$SITE_DIR/.env" && set +o allexport
    envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE" || return 1
    echo -e "${GREEN}✅ Created docker-compose.yml${NC}"
  else
    echo -e "${RED}❌ docker-compose.yml template not found${NC}"
    return 1
  fi

  # 🚀 Start containers
  run_unless_test run_in_dir "$SITE_DIR" docker compose up -d || return 1

  echo -e "${YELLOW}⏳ Checking container startup...${NC}"
  for i in {1..30}; do
    if is_container_running "$CONTAINER_PHP" && is_container_running "$CONTAINER_DB"; then
      echo -e "${GREEN}✅ Container is ready.${NC}"
      break
    fi
    run_unless_test sleep 1
  done

  if ! is_container_running "$CONTAINER_PHP" || ! is_container_running "$CONTAINER_DB"; then
    echo -e "${RED}❌ Container not ready after 30 seconds.${NC}"
    return 1
  fi

  # 🔐 Install SSL + WordPress
  generate_ssl_cert "$domain" "$SSL_DIR" || return 1
  run_unless_test bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh" "$site_name" || return 1

  # 📦 Display information
  WP_INFO_FILE="$SITE_DIR/.wp-info"
  if [ -f "$WP_INFO_FILE" ]; then
    echo -e "${GREEN}\n🎉 WordPress installed successfully for $site_name${NC}"
    cat "$WP_INFO_FILE"
    rm -f "$WP_INFO_FILE"
  fi

  # 🔁 Restart NGINX
  nginx_restart || return 1

  # 🧑‍🔧 Permissions
  if is_container_running "$CONTAINER_PHP"; then
    run_unless_test docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup /var/www/ || return 1
  else
    echo -e "${YELLOW}⚠️ Container PHP not running, skipping permissions.${NC}"
  fi

  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] ✅ COMPLETED: $site_name =====" >> "$LOG_FILE"
  echo "✅ DONE_CREATE_WEBSITE: $site_name"
}
