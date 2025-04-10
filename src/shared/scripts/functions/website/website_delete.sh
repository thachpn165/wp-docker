# =====================================
# 🗑️ website_management_delete_logic – Delete a WordPress Website (Logic only)
# =====================================

# =====================================
# 🗑️ website_management_delete_logic – Delete a WordPress Website (Logic only)
# =====================================

website_management_delete_logic() {
  local domain="$1"
  local backup_enabled="$2"

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi
  #shellcheck disable=SC2153
  SITE_DIR="$SITES_DIR/$domain"

  if ! is_directory_exist "$SITE_DIR"; then
    print_msg error "$ERROR_WEBSITE_NOT_EXIST: $domain"
    return 1
  fi

  MARIADB_VOLUME="${domain//./}${DB_VOLUME_SUFFIX}"
  SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$domain.conf"

  debug_log "Deleting website '$domain'..."
  debug_log "MariaDB Volume: $MARIADB_VOLUME"
  debug_log "Site conf file: $SITE_CONF_FILE"
  debug_log "Site directory: $SITE_DIR"
  debug_log "backup_enabled: $backup_enabled"

  if [[ "$backup_enabled" == true ]]; then
    print_msg step "$MSG_WEBSITE_BACKUP_BEFORE_REMOVE: $domain"

    ARCHIVE_DIR="$ARCHIVES_DIR/old_website/${domain}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$ARCHIVE_DIR"

    print_msg step "$MSG_WEBSITE_BACKING_UP_DB: $domain"
    run_cmd "bash $CLI_DIR/database_export.sh --domain=$domain --save_location=$ARCHIVE_DIR/${domain}_db.sql" true

    print_msg step "$MSG_WEBSITE_BACKING_UP_FILES: $SITE_DIR/wordpress"
    run_cmd "bash $CLI_DIR/backup_file.sh --domain=$domain" true

    print_msg success "$MSG_WEBSITE_BACKUP_FILE_CREATED: $ARCHIVE_DIR"
  fi

  print_msg step "$MSG_WEBSITE_STOPPING_CONTAINERS: $domain"
  run_cmd "docker compose -f $SITE_DIR/docker-compose.yml down" true
  debug_log "Stopped containers for website '$domain'."

  OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
  MOUNT_ENTRY="      - ../../sites/$domain/wordpress:/var/www/$domain"
  MOUNT_LOGS="      - ../../sites/$domain/logs:/var/www/logs/$domain"

  if [[ -f "$OVERRIDE_FILE" ]]; then
    print_msg step "$MSG_NGINX_REMOVE_MOUNT: $domain"
    nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
  fi

  print_msg step "$MSG_WEBSITE_DELETING_DIRECTORY: $SITE_DIR"
  run_cmd "rm -rf \"$SITE_DIR\"" true
  print_msg success "$SUCCESS_DIRECTORY_REMOVE: $SITE_DIR"

  print_msg step "$MSG_WEBSITE_DELETING_SSL: $domain"
  run_cmd "rm -rf \"$SSL_DIR/$domain.crt\"" true
  run_cmd "rm -rf \"$SSL_DIR/$domain.key\"" true
  print_msg success "$SUCCESS_SSL_CERTIFICATE_REMOVED: $domain"

  print_msg step "$MSG_WEBSITE_DELETING_VOLUME: $MARIADB_VOLUME"
  run_cmd "docker volume rm \"$MARIADB_VOLUME\"" true
  print_msg success "$SUCCESS_CONTAINER_VOLUME_REMOVE: $MARIADB_VOLUME"

  if is_file_exist "$SITE_CONF_FILE"; then
    print_msg step "$MSG_WEBSITE_DELETING_NGINX_CONF: $SITE_CONF_FILE"
    remove_file "$SITE_CONF_FILE"
    print_msg success "$SUCCESS_FILE_REMOVED: $SITE_CONF_FILE"
  fi

  if crontab -l 2>/dev/null | grep -q "$domain"; then
    tmp_cron=$(mktemp)
    crontab -l | grep -v "$domain" > "$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"
    print_msg success "$SUCCESS_CRON_REMOVED: $domain"
  fi

  # Remove entry in .config.json
  json_delete_site_key "$domain"
  print_msg success "$SUCCESS_CONFIG_SITE_REMOVED: $domain"

  nginx_restart
  print_msg success "$SUCCESS_WEBSITE_REMOVED: $domain"
}