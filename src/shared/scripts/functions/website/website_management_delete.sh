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
    #echo -e "${RED}${CROSSMARK} Missing domain parameter.${NC}"
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  SITE_DIR="$SITES_DIR/$domain"
  ENV_FILE="$SITE_DIR/.env"

  if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}${CROSSMARK} Website '$domain' does not exist.${NC}"
    return 1
  fi

  #if ! is_file_exist "$ENV_FILE"; then
  #  echo -e "${RED}${CROSSMARK} Website .env file not found!${NC}"
  #  return 1
  #fi

  #domain=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
  MARIADB_VOLUME="${domain//./}${DB_VOLUME_SUFFIX}"
  SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$domain.conf"

  # Debug mode
  debug_log "Deleting website '$domain'..."
  debug_log "MariaDB Volume: $MARIADB_VOLUME"
  debug_log "Site conf file: $SITE_CONF_FILE"
  debug_log "Site directory: $SITE_DIR"

  # Nếu backup_enabled=true thì tiến hành backup
  if [[ "$backup_enabled" == true ]]; then
    print_msg step "$MSG_WEBSITE_BACKUP_BEFORE_REMOVE: $domain"
    ARCHIVE_DIR="$ARCHIVES_DIR/old_website/${domain}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$ARCHIVE_DIR"

    DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
    DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
    DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")

    if [[ -n "$DB_NAME" && -n "$DB_USER" && -n "$DB_PASS" ]]; then
      #echo -e "${YELLOW}📦 Backing up database...${NC}"
      print_msg step "$MSG_WEBSITE_BACKING_UP_DB: $DB_NAME"
      run_cmd "docker exec \"${domain}-mariadb\" sh -c 'exec mysqldump -u$DB_USER -p\"$DB_PASS\" $DB_NAME' > \"$ARCHIVE_DIR/${domain}_db.sql\"" true
    fi

    #echo -e "${YELLOW}📦 Compressing WordPress source code...${NC}"
    print_msg step "$MSG_WEBSITE_BACKING_UP_FILES: $SITE_DIR/wordpress"
    tar -czf "$ARCHIVE_DIR/${domain}_wordpress.tar.gz" -C "$SITE_DIR/wordpress" . || true

    print_msg success "$MSG_WEBSITE_BACKUP_FILE_CREATED: $ARCHIVE_DIR"
  fi

  # 🛑 Stop containers
  print_msg step "$MSG_WEBSITE_STOPPING_CONTAINERS: $domain"
  run_cmd "docker compose -f \"$SITE_DIR/docker-compose.yml\" down"
  debug_log "Stopped containers for website '$domain'."

  # 🧹 Remove override entry before deleting directory using nginx_remove_mount_docker
  OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
  MOUNT_ENTRY="      - ../../sites/$domain/wordpress:/var/www/$domain"
  MOUNT_LOGS="      - ../../sites/$domain/logs:/var/www/logs/$domain"

  if [ -f "$OVERRIDE_FILE" ]; then
      print_msg step "$MSG_NGINX_REMOVE_MOUNT: $domain"
      nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
  fi

  # 🗂️ Delete website directory
  print_msg step "$MSG_WEBSITE_DELETING_DIRECTORY: $SITE_DIR"
  run_cmd "rm -rf $SITE_DIR"
  print_msg success "$SUCCESS_DIRECTORY_REMOVE: $SITE_DIR"

  # 🔐 Delete SSL certificate
  print_msg step "$MSG_WEBSITE_DELETING_SSL: $domain"
  run_cmd "rm -rf $SSL_DIR/$domain.crt"
  run_cmd "rm -rf $SSL_DIR/$domain.key"
  print_msg success "$SUCCESS_SSL_CERTIFICATE_REMOVED: $domain"

  # 🗃️ Delete DB volume
  #remove_volume "$MARIADB_VOLUME"
  print_msg step "$MSG_WEBSITE_DELETING_VOLUME: $MARIADB_VOLUME"
  run_cmd "remove_volume \"$MARIADB_VOLUME\""
  print_msg success "$SUCCESS_CONTAINER_VOLUME_REMOVE: $MARIADB_VOLUME"

  # 🧾 Delete NGINX configuration
  if is_file_exist "$SITE_CONF_FILE"; then
    print_msg step "$MSG_WEBSITE_DELETING_NGINX_CONF: $SITE_CONF_FILE"
    remove_file "$SITE_CONF_FILE"
    print_msg success "$SUCCESS_FILE_REMOVED: $SITE_CONF_FILE"
  fi

  # 🕒 Delete cronjob if exists
  if crontab -l 2>/dev/null | grep -q "$domain"; then
    tmp_cron=$(mktemp)
    crontab -l | grep -v "$domain" > "$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"
    print_msg success "$SUCCESS_CRON_REMOVED: $domain"
  fi

  # 🔁 Restart NGINX Proxy
  nginx_restart
  print_msg success "$SUCCESS_WEBSITE_REMOVED: $domain"
}
