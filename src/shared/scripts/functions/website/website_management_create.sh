# =====================================
# 🐋 website_management_create_logic – Main Logic (used by menu & CLI)
# =====================================
website_management_create_logic() {

  local domain="$1"
  local php_version="$2"

  SITE_DIR="$SITES_DIR/$domain"  # Use domain for directory naming
  CONTAINER_PHP="${domain}-php"  # Container name using domain
  CONTAINER_DB="${domain}-mariadb"
  MARIADB_VOLUME="${domain}_mariadb_data"

  # ❌ Check if site already exists
 if is_directory_exist "$SITE_DIR" false; then
    echo -e "${RED}❌ Website '$domain' already exists.${NC}"
    return 1
  fi

  # 🧹 Remove existing volume if exists
  if docker volume ls --format '{{.Name}}' | grep -q "^$MARIADB_VOLUME$"; then
    echo -e "${YELLOW}${WARNING} Existing MariaDB volume '$MARIADB_VOLUME' found. Removing to ensure clean setup...${NC}"
    run_unless_test docker volume rm "$MARIADB_VOLUME"
  fi

  # 🗘️ Create log
  mkdir -p "$LOGS_DIR"
  LOG_FILE="$LOGS_DIR/${domain}-setup.log"
  touch "$LOG_FILE"
  run_unless_test bash -c "exec > >(tee -a \"$LOG_FILE\") 2>&1"
  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] STARTING SITE CREATION: $domain =====" >> "$LOG_FILE"

  # 🧱 Create directory structure
  mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
  touch "$SITE_DIR/logs/access.log" "$SITE_DIR/logs/error.log"
  chmod 666 "$SITE_DIR/logs/"*.log

  # Copy .template_version file if exists
  TEMPLATE_VERSION_FILE="$TEMPLATES_DIR/.template_version"
  if is_file_exist "$TEMPLATE_VERSION_FILE"; then
    cp "$TEMPLATE_VERSION_FILE" "$SITE_DIR/.template_version"
    echo -e "${GREEN}${CHECKMARK} Copied .template_version to $SITE_DIR${NC}"
  else
    echo -e "${YELLOW}${WARNING} No .template_version file found in shared/templates.${NC}"
  fi

  # 🔧 Configure NGINX
  update_nginx_override_mounts "$domain" || return 1
  export domain php_version
  run_unless_test bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh" || return 1

  # ⚙️ Create configurations
  copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini" || return 1
  apply_mariadb_config "$SITE_DIR/mariadb/conf.d/custom.cnf" || return 1
  create_optimized_php_fpm_config "$SITE_DIR/php/php-fpm.conf" || return 1
  website_create_env "$SITE_DIR" "$domain" "$php_version" || return 1

  # SSL
  generate_ssl_cert "$domain" "$SSL_DIR" || return 1
  # 🛠️ Create docker-compose.yml
  TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
  TARGET_FILE="$SITE_DIR/docker-compose.yml"
  if is_file_exist "$TEMPLATE_FILE"; then
    set -o allexport && source "$SITE_DIR/.env" && set +o allexport
    envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE" || return 1
    echo -e "${GREEN}${CHECKMARK} Created docker-compose.yml${NC}"
  else
    echo -e "${RED}${CROSSMARK} docker-compose.yml template not found${NC}"
    return 1
  fi

  # 🚀 Start containers
  run_unless_test run_in_dir "$SITE_DIR" docker compose up -d || return 1

  echo -e "${YELLOW}⏳ Checking container startup...${NC}"
  for i in {1..30}; do
    if is_container_running "$CONTAINER_PHP" && is_container_running "$CONTAINER_DB"; then
      echo -e "${GREEN}${CHECKMARK} Container is ready.${NC}"
      break
    fi
    run_unless_test sleep 1
  done

  if ! is_container_running "$CONTAINER_PHP" || ! is_container_running "$CONTAINER_DB"; then
    echo -e "${RED}${CROSSMARK} Container not ready after 30 seconds.${NC}"
    return 1
  fi

  # 🔁 Restart NGINX
  nginx_restart || return 1

  # 🧑‍💻 Permissions
  if is_container_running "$CONTAINER_PHP"; then
    run_unless_test docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup /var/www/ || return 1
  else
    echo -e "${YELLOW}${WARNING} Container PHP not running, skipping permissions.${NC}"
  fi

  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] ✅ COMPLETED: $domain =====" >> "$LOG_FILE"
}
