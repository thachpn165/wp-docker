wordpress_migration_logic() {
  # =====================================
  # wordpress_migration_logic: Migrate a WordPress site from archive to live environment
  # Parameters:
  #   $1 - domain
  # Behavior:
  #   - Validates archive and SQL files
  #   - Recreates or creates site if needed
  #   - Restores source code and database
  #   - Fixes wp-config.php with correct DB credentials and table prefix
  #   - Offers Let's Encrypt SSL installation
  #   - Verifies DNS record matches server IP
  # =====================================

  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_DOMAIN_REQUIRED"
    return 1
  fi

  local archive_dir="$BASE_DIR/archives/$domain"
  local site_dir="$SITES_DIR/$domain"
  local web_root="$site_dir/wordpress"
  local sql_file archive_file server_ip
  local mariadb_container
  mariadb_container=$(json_get_site_value "$domain" "CONTAINER_DB")

  server_ip=$(curl -s ifconfig.me)

  if ! is_directory_exist "$archive_dir"; then
    print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$archive_dir")"
    return 1
  fi

  sql_file=$(find "$archive_dir" -type f -name "*.sql" | head -n1)
  archive_file=$(find "$archive_dir" -type f \( -name "*.zip" -o -name "*.tar.gz" \) | head -n1)

  if [[ ! -f "$sql_file" ]]; then
    print_and_debug error "$(printf "$ERROR_FILE_NOT_FOUND" "$archive_dir/*.sql")"
    return 1
  fi

  if [[ ! -f "$archive_file" ]]; then
    print_and_debug error "$(printf "$ERROR_FILE_NOT_FOUND" "$archive_dir/*.zip or *.tar.gz")"
    return 1
  fi

  if [[ -d "$site_dir" ]]; then
    print_msg warning "$(printf "$MSG_WEBSITE_EXIST" "$domain")"
    confirm_action "$QUESTION_OVERWRITE_SITE" || {
      print_msg warning "$MSG_OPERATION_CANCELLED"
      return 0
    }

    print_msg step "$STEP_WORDPRESS_MIGRATION_DELETING_OLD_SOURCE: $web_root"
    rm -rf "$web_root"
    mkdir -p "$web_root"
    print_msg success "$SUCCESS_DIRECTORY_REMOVE"
  else
    print_msg warning "$(printf "$ERROR_SITE_NOT_EXIST" "$domain")"
    confirm_action "$(printf "$PROMPT_WEBSITE_CREATE_CONFIRM" "$domain")" || {
      print_msg warning "$MSG_OPERATION_CANCELLED"
      return 0
    }

    bash "$MENU_DIR/website/website_create_menu.sh"
    mariadb_container=$(json_get_site_value "$domain" "CONTAINER_DB")
  fi

  print_msg step "$STEP_WORDPRESS_MIGRATION_EXTRACTING: $archive_file"
  if [[ "$archive_file" == *.zip ]]; then
    unzip -q "$archive_file" -d "$web_root"
  else
    tar -xzf "$archive_file" -C "$web_root"
  fi

  print_msg step "$STEP_WORDPRESS_MIGRATION_IMPORTING_DB: $sql_file"
  local db_name db_user db_pass
  db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
  db_user=$(json_get_site_value "$domain" "MYSQL_USER")
  db_pass=$(json_get_site_value "$domain" "MYSQL_PASSWORD")
  bash "$CLI_DIR/database_import.sh" --domain="$domain" --backup_file="$sql_file"

  print_msg step "$STEP_WORDPRESS_CHECK_DB_PREFIX"
  local prefix
  prefix=$(docker exec --env MYSQL_PWD="$db_pass" "$mariadb_container" \
    mysql -u "$db_user" "$db_name" -e "SHOW TABLES;" |
    tail -n +2 | awk -F_ '/_/ {print $1"_" ; exit}')

  local config_file="$web_root/wp-config.php"
  if [[ -f "$config_file" ]]; then
    local config_prefix
    config_prefix=$(grep "table_prefix" "$config_file" | grep -o "'[^']*'" | sed "s/'//g")
    [[ -z "$config_prefix" ]] && config_prefix="wp_"

    if [[ "$prefix" != "$config_prefix" ]]; then
      print_msg warning "$(printf "$WARNING_TABLE_PREFIX_MISMATCH" "$prefix" "$config_prefix")"
      local table_prefix="wp_"
      sedi "s/\\$table_prefix *= *'[^']*'/\\$table_prefix = '$prefix'/" "$config_file"
      print_msg success "$SUCCESS_WORDPRESS_UPDATE_PREFIX: $prefix"
    fi

    print_msg step "$STEP_WORDPRESS_UPDATE_CONFIG_DB"
    sedi "s/define( *'DB_NAME'.*/define('DB_NAME', '$db_name');/" "$config_file"
    sedi "s/define( *'DB_USER'.*/define('DB_USER', '$db_user');/" "$config_file"
    sedi "s/define( *'DB_PASSWORD'.*/define('DB_PASSWORD', '$db_pass');/" "$config_file"
    print_msg success "$SUCCESS_WP_CONFIG_DONE"
  else
    print_and_debug error "$(printf "$ERROR_FILE_NOT_FOUND" "$config_file")"
    return 1
  fi

  print_msg step "$STEP_SSL_LETSENCRYPT"
  print_msg info "$(printf "$INFO_LE_DOMAIN" "$domain")"
  confirm_action "$QUESTION_INSTALL_SSL"
  if [[ $? -eq 0 ]]; then
    print_msg info "$(printf "$INFO_INSTALLING_SSL" "$domain")"
    bash "$CLI_DIR/ssl_install_letsencrypt.sh" --domain="$domain"
  else
    print_msg info "$INFO_SKIP_SSL_INSTALL"
  fi

  print_msg step "$STEP_WEBSITE_CHECK_DNS"
  if ! dig +short "$domain" | grep -q "$server_ip"; then
    print_msg warning "$(printf "$ERROR_DOMAIN_NOT_POINT_TO_SERVER" "$domain" "$server_ip")"
  else
    print_msg success "$(printf "$SUCCESS_DOMAIN_POINTS_TO_IP" "$domain" "$server_ip")"
  fi

  echo ""
  print_msg success "$(printf "$SUCCESS_MIGRATION_DONE" "$domain")"
  print_msg tip "$TIP_MIGRATION_COMPLETE_USE_CACHE"
}