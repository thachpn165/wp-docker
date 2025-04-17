# =====================================
# website_prompt_delete: Prompt user to delete a WordPress site with optional backup
# Behavior:
#   - Ask for domain and confirmation
#   - Offer backup option
#   - Call CLI wrapper to execute logic
# =====================================
website_prompt_delete() {
  safe_source "$CLI_DIR/website_manage.sh"
  safe_source "$CLI_DIR/database_actions.sh"
  # === UI ===
  print_msg title "$TITLE_WEBSITE_DELETE"

  # Select website
  local domain
  website_get_selected domain
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    exit 1
  fi

  # Ask for backup before delete
  backup_enabled=true # default
  backup_confirm=$(get_input_or_test_value "$PROMPT_BACKUP_BEFORE_DELETE $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "yes")
  [[ "$backup_confirm" != "yes" ]] && backup_enabled=false
  debug_log "[DEBUG] Backup before delete: $backup_enabled"

  # Ask for final delete confirmation
  delete_confirm=$(get_input_or_test_value "$PROMPT_WEBSITE_DELETE_CONFIRM $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "no")
  if [[ "$delete_confirm" != "yes" ]]; then
    print_msg warning "$WARNING_ACTION_CANCELLED"
    exit 0
  fi

  # Run deletion logic
  website_cli_delete \
    --domain="$domain" \
    --backup_enabled="$backup_enabled" || return 1
}

# =====================================
# website_logic_delete: Logic to delete a WordPress website
# Parameters:
#   $1 - domain
#   $2 - backup_enabled (true/false)
# Behavior:
#   - Stop containers, backup site if enabled
#   - Remove Docker volume, NGINX mount, config, SSL, crontab, .config.json entry
#   - Reload NGINX
# =====================================
website_logic_delete() {
  safe_source "$CLI_DIR/backup_website.sh"
  local domain="$1"
  local backup_enabled="$2"

  if [[ -z "$domain" ]]; then
    website_prompt_delete
  fi

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

  SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$domain.conf"

  debug_log "Deleting website '$domain'..."
  debug_log "Site conf file: $SITE_CONF_FILE"
  debug_log "Site directory: $SITE_DIR"
  debug_log "backup_enabled: $backup_enabled"

  if [[ "$backup_enabled" == true ]]; then
    print_msg step "$MSG_WEBSITE_BACKUP_BEFORE_REMOVE: $domain"

    local archive_file old_web_dir
    old_web_dir="$ARCHIVES_DIR/old_website/$domain"
    archive_file="$ARCHIVES_DIR/old_website/${domain}-$(date +%Y%m%d-%H%M%S)_${domain}_db.sql"
    is_directory_exist "$old_web_dir" || mkdir -p "$old_web_dir"
    print_msg step "$MSG_WEBSITE_BACKING_UP_DB: $domain"
    database_cli_export --domain="$domain" --save_location="$archive_file"

    print_msg step "$MSG_WEBSITE_BACKING_UP_FILES: $SITE_DIR/wordpress"
    backup_cli_file --domain="$domain" true

    print_msg success "$MSG_WEBSITE_BACKUP_FILE_CREATED: $archive_file"
  fi

  print_msg step "$MSG_WEBSITE_STOPPING_CONTAINERS: $domain"
  run_cmd "docker compose -f $SITE_DIR/docker-compose.yml down" true
  debug_log "Stopped containers for website '$domain'."

  # Xoá database/user nếu có trong .config.json (không cần tự xóa key vì json_delete_site_key sẽ xử lý toàn bộ)
  local db_name db_user
  db_name="$(json_get_site_value "$domain" "db_name")"
  db_user="$(json_get_site_value "$domain" "db_user")"

  if [[ -n "$db_name" && -n "$db_user" ]]; then
    mysql_logic_delete_db_and_user "$domain" "$db_name" "$db_user"
  fi

  OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
  MOUNT_ENTRY="      - ../../../../sites/$domain/wordpress:/var/www/$domain"
  MOUNT_LOGS="      - ../../../../sites/$domain/logs:/var/www/logs/$domain"

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

  if is_file_exist "$SITE_CONF_FILE"; then
    print_msg step "$MSG_WEBSITE_DELETING_NGINX_CONF: $SITE_CONF_FILE"
    remove_file "$SITE_CONF_FILE"
    print_msg success "$SUCCESS_FILE_REMOVED: $SITE_CONF_FILE"
  fi

  if crontab -l 2>/dev/null | grep -q "$domain"; then
    tmp_cron=$(mktemp)
    crontab -l | grep -v "$domain" >"$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"
    print_msg success "$SUCCESS_CRON_REMOVED: $domain"
  fi

  # Remove entry in .config.json
  json_delete_site_key "$domain"
  print_msg success "$SUCCESS_CONFIG_SITE_REMOVED: $domain"
  safe_source "$CORE_LIB_DIR/nginx_utils.sh"
  nginx_restart
  print_msg success "$SUCCESS_WEBSITE_REMOVED: $domain"
}
