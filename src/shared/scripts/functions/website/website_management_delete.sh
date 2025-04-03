# =====================================
# 🗑️ website_management_delete_logic – Delete a WordPress Website (Logic only)
# =====================================

website_management_delete_logic() {
  local domain="$1"
  local backup_enabled="${2:-false}"  # Tham số backup_enabled mặc định là false

  if [[ "$TEST_MODE" == true ]]; then
    backup_enabled=false
  fi

  if [[ -z "$domain" ]]; then
    echo -e "${RED}${CROSSMARK} Missing domain parameter.${NC}"
    return 1
  fi

  SITE_DIR="$SITES_DIR/$domain"
  ENV_FILE="$SITE_DIR/.env"

  if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}${CROSSMARK} Website '$domain' does not exist.${NC}"
    return 1
  fi

  if ! is_file_exist "$ENV_FILE"; then
    echo -e "${RED}${CROSSMARK} Website .env file not found!${NC}"
    return 1
  fi

  DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
  MARIADB_VOLUME="${domain//./}_mariadb_data"
  SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$domain.conf"

  # Nếu backup_enabled=true thì tiến hành backup
  if [[ "$backup_enabled" == true ]]; then
    echo -e "${YELLOW}📦 Creating backup before deletion...${NC}"
    ARCHIVE_DIR="$ARCHIVES_DIR/old_website/${domain}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$ARCHIVE_DIR"

    DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
    DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
    DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")

    if [[ -n "$DB_NAME" && -n "$DB_USER" && -n "$DB_PASS" ]]; then
      echo -e "${YELLOW}📦 Backing up database...${NC}"
      docker exec "${domain}-mariadb" sh -c "exec mysqldump -u$DB_USER -p\"$DB_PASS\" $DB_NAME" \
        > "$ARCHIVE_DIR/${domain}_db.sql" 2>/dev/null || true
    fi

    echo -e "${YELLOW}📦 Compressing WordPress source code...${NC}"
    tar -czf "$ARCHIVE_DIR/${domain}_wordpress.tar.gz" -C "$SITE_DIR/wordpress" . || true

    echo -e "${GREEN}${CHECKMARK} Website backup created at: $ARCHIVE_DIR${NC}"
  fi

  # 🛑 Stop containers
  run_in_dir "$SITE_DIR" docker compose down

  # 🧹 Remove override entry before deleting directory using nginx_remove_mount_docker
  OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
  MOUNT_ENTRY="      - ../../sites/$domain/wordpress:/var/www/$domain"
  MOUNT_LOGS="      - ../../sites/$domain/logs:/var/www/logs/$domain"

  if [ -f "$OVERRIDE_FILE" ]; then
      nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
  fi

  # 🗂️ Delete website directory
  remove_directory "$SITE_DIR"
  echo -e "${GREEN}${CHECKMARK} Deleted website directory: $SITE_DIR${NC}"

  # 🔐 Delete SSL certificate
  remove_file "$SSL_DIR/$DOMAIN.crt"
  remove_file "$SSL_DIR/$DOMAIN.key"
  echo -e "${GREEN}${CHECKMARK} Deleted SSL certificate (if any).${NC}"

  # 🗃️ Delete DB volume
  remove_volume "$MARIADB_VOLUME"
  echo -e "${GREEN}${CHECKMARK} Deleted DB volume: $MARIADB_VOLUME${NC}"

  # 🧾 Delete NGINX configuration
  if is_file_exist "$SITE_CONF_FILE"; then
    remove_file "$SITE_CONF_FILE"
    echo -e "${GREEN}${CHECKMARK} Deleted NGINX configuration file.${NC}"
  fi

  # 🕒 Delete cronjob if exists
  if crontab -l 2>/dev/null | grep -q "$domain"; then
    tmp_cron=$(mktemp)
    crontab -l | grep -v "$domain" > "$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"
    echo -e "${GREEN}${CHECKMARK} Deleted cronjob related to site.${NC}"
  fi

  # 🔁 Restart NGINX Proxy
  nginx_restart
  echo -e "${GREEN}${CHECKMARK} Website '$domain' deleted successfully.${NC}"
}