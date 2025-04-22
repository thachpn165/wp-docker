safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"
safe_source "$FUNCTIONS_DIR/website_loader.sh"
safe_source "$CLI_DIR/database_actions.sh"
safe_source "$CLI_DIR/ssl_install.sh"
# =====================================
wordpress_prompt_migration() {

  # === Display welcome message ===
  print_msg title "$TITLE_MIGRATION_TOOL"
  echo ""
  print_msg warning "$WARNING_MIGRATION_PREPARE"
  echo "  - $TIP_MIGRATION_FOLDER_PATH: ${BLUE}$INSTALL_DIR/archives/<domain.ltd> <- Replace your domain${NC}"
  echo "  - $TIP_MIGRATION_FOLDER_CONTENT"
  echo "     - $TIP_MIGRATION_SOURCE"
  echo "     - $TIP_MIGRATION_SQL"
  echo ""

  # === Confirm user is ready ===
  ready=$(get_input_or_test_value "$QUESTION_MIGRATION_READY" "${TEST_READY:-y}")
  if [[ "$ready" != "y" && "$ready" != "Y" ]]; then
    print_msg error "$ERROR_MIGRATION_CANCEL"
    exit 1
  fi

  echo ""
  domain=$(get_input_or_test_value "$PROMPT_ENTER_DOMAIN_TO_MIGRATE" "${TEST_DOMAIN:-example.com}")
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_DOMAIN_REQUIRED"
    exit 1
  fi

  echo ""
  print_msg info "$(printf "$INFO_MIGRATION_STARTING" "$domain")"
  wordpress_cli_migration --domain="$domain"
}
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
wordpress_migration_logic() {

  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_DOMAIN_REQUIRED"
    return 1
  fi
  _is_valid_domain "$domain" || return 1
  local archive_dir="$BASE_DIR/archives/$domain"
  local site_dir="$SITES_DIR/$domain"
  local web_root="$site_dir/wordpress"
  local sql_file archive_file server_ip
  local mariadb_container="$MYSQL_CONTAINER_NAME"

  server_ip=$(curl -s ifconfig.me)

  if ! _is_directory_exist "$archive_dir"; then
    print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$archive_dir")"
    local formatted_important_prepare_folder
    formatted_important_prepare_folder=$(printf "$IMPORTANT_PREPARE_MIGRATION_FOLDER" "$archive_dir")
    print_msg important "$formatted_important_prepare_folder"
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
    print_msg warning "$MSG_WEBSITE_EXIST: $domain"
    forrmatted_msg_override="$(printf "$QUESTION_OVERWRITE_SITE" "${YELLOW}$domain${NC}")"
    confirm_action "$forrmatted_msg_override" || {
      print_msg cancel "$MSG_OPERATION_CANCELLED"
      return 0
    }

    print_msg step "$STEP_WORDPRESS_MIGRATION_DELETING_OLD_SOURCE: $web_root"
    remove_directory "$web_root"
    mkdir -p "$web_root"
    print_msg success "$SUCCESS_DIRECTORY_REMOVE"
  else
    print_msg warning "$(printf "$ERROR_SITE_NOT_EXIST" "$domain")"
    confirm_action "$(printf "$PROMPT_WEBSITE_CREATE_CONFIRM" "$domain")" || {
      print_msg warning "$MSG_OPERATION_CANCELLED"
      return 0
    }

    website_prompt_create
  fi

  print_msg step "$STEP_WORDPRESS_MIGRATION_EXTRACTING: $archive_file"
  if [[ "$archive_file" == *.zip ]]; then
    unzip -q "$archive_file" -d "$web_root"
  else
    tar -xzf "$archive_file" -C "$web_root"
  fi

  print_msg step "$STEP_WORDPRESS_MIGRATION_IMPORTING_DB: $sql_file"
  local db_name db_user db_pass
  db_name=$(json_get_site_value "$domain" "db_name")
  db_user=$(json_get_site_value "$domain" "db_user")
  db_pass=$(json_get_site_value "$domain" "db_pass")
  database_cli_import --domain="$domain" --backup_file="$sql_file"

  print_msg step "$STEP_WORDPRESS_CHECK_DB_PREFIX"
  if ! _is_container_running "$mariadb_container"; then
    print_and_debug error "$(printf "$ERROR_CONTAINER_NOT_RUNNING" "$mariadb_container")"
    return 1
  fi
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
    ssl_cli_install_letsencrypt --domain="$domain"
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
