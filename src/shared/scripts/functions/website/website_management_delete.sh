# =====================================
# 🗑️ website_management_delete – Delete a WordPress Website
# =====================================

website_management_delete() {
  echo -e "${YELLOW}📋 List of websites that can be deleted:${NC}"
  site_list=( $(ls -1 "$SITES_DIR") )

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ No websites available to delete.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  [[ "$TEST_MODE" != true ]] && read -p "Enter the number corresponding to the website to delete: " site_index
  site_name="${site_list[$site_index]}"
  SITE_DIR="$SITES_DIR/$site_name"
  ENV_FILE="$SITE_DIR/.env"

  if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}❌ Website '$site_name' does not exist.${NC}"
    return 1
  fi

  if ! is_file_exist "$ENV_FILE"; then
    echo -e "${RED}❌ Website .env file not found!${NC}"
    return 1
  fi

  DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
  MARIADB_VOLUME="${site_name}_mariadb_data"
  SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$site_name.conf"

  echo -e "${RED}${BOLD}🚨 IMPORTANT WARNING 🚨${NC}"
  echo -e "${RED}❗ Website deletion is IRREVERSIBLE ❗${NC}"
  echo -e "${YELLOW}📌 Please backup your data before proceeding.${NC}"

  if ! confirm_action "⚠️ Are you sure you want to delete website '$site_name' ($DOMAIN)?"; then
    echo -e "${YELLOW}⚠️ Deletion cancelled.${NC}"
    return 1
  fi

  # 🧰 Suggest backup if needed
  if confirm_action "💾 Would you like to backup source code and database before deletion?"; then
    ARCHIVE_DIR="$ARCHIVES_DIR/old_website/${site_name}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$ARCHIVE_DIR"

    DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
    DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
    DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")

    if [[ -n "$DB_NAME" && -n "$DB_USER" && -n "$DB_PASS" ]]; then
      echo -e "${YELLOW}📦 Backing up database...${NC}"
      docker exec "${site_name}-mariadb" sh -c "exec mysqldump -u$DB_USER -p\"$DB_PASS\" $DB_NAME" \
        > "$ARCHIVE_DIR/${site_name}_db.sql" 2>/dev/null || true
    fi

    echo -e "${YELLOW}📦 Compressing WordPress source code...${NC}"
    tar -czf "$ARCHIVE_DIR/${site_name}_wordpress.tar.gz" -C "$SITE_DIR/wordpress" . || true

    echo -e "${GREEN}✅ Website backup created at: $ARCHIVE_DIR${NC}"
  fi

  # 🛑 Stop containers
  run_in_dir "$SITE_DIR" docker compose down

  # 🧹 Remove override entry before deleting directory
  OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
  MOUNT_ENTRY="      - ../../sites/$site_name/wordpress:/var/www/$site_name"
  MOUNT_LOGS="      - ../../sites/$site_name/logs:/var/www/logs/$site_name"
  if [ -f "$OVERRIDE_FILE" ]; then
    temp_file=$(mktemp)
    grep -vF "$MOUNT_ENTRY" "$OVERRIDE_FILE" | grep -vF "$MOUNT_LOGS" > "$temp_file"
    mv "$temp_file" "$OVERRIDE_FILE"
    echo -e "${GREEN}✅ Removed website entry from docker-compose.override.yml.${NC}"
  fi

  # 🗂️ Delete website directory
  remove_directory "$SITE_DIR"
  echo -e "${GREEN}✅ Deleted website directory: $SITE_DIR${NC}"

  # 🔐 Delete SSL certificate
  remove_file "$SSL_DIR/$DOMAIN.crt"
  remove_file "$SSL_DIR/$DOMAIN.key"
  echo -e "${GREEN}✅ Deleted SSL certificate (if any).${NC}"

  # 🗃️ Delete DB volume
  remove_volume "$MARIADB_VOLUME"
  echo -e "${GREEN}✅ Deleted DB volume: $MARIADB_VOLUME${NC}"

  # 🧾 Delete NGINX configuration
  if is_file_exist "$SITE_CONF_FILE"; then
    remove_file "$SITE_CONF_FILE"
    echo -e "${GREEN}✅ Deleted NGINX configuration file.${NC}"
  fi

  # 🕒 Delete cronjob if exists
  if crontab -l 2>/dev/null | grep -q "$site_name"; then
    tmp_cron=$(mktemp)
    crontab -l | grep -v "$site_name" > "$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"
    echo -e "${GREEN}✅ Deleted cronjob related to site.${NC}"
  fi

  # 🔁 Restart NGINX Proxy
  nginx_restart
  echo -e "${GREEN}✅ Website '$site_name' deleted successfully.${NC}"
}
