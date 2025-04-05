#!/bin/bash

wordpress_migration_logic() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    echo -e "${RED}${CROSSMARK} Domain is required.${NC}"
    return 1
  fi

  local archive_dir="$BASE_DIR/archives/$domain"
  local site_dir="$SITES_DIR/$domain"
  local web_root="$site_dir/wordpress"
  local sql_file
  local archive_file
  local mariadb_container="$domain-mariadb"

  # Check archive directory
  is_directory_exist "$archive_dir"

  # Find SQL and source files
  sql_file=$(find "$archive_dir" -type f -name "*.sql" | head -n1)
  archive_file=$(find "$archive_dir" -type f \( -name "*.zip" -o -name "*.tar.gz" \) | head -n1)

  if [[ ! -f "$sql_file" ]]; then
    echo -e "${RED}${CROSSMARK} No .sql file found in $archive_dir${NC}"
    return 1
  fi

  if [[ ! -f "$archive_file" ]]; then
    echo -e "${RED}${CROSSMARK} No source archive (.zip or .tar.gz) found in $archive_dir${NC}"
    return 1
  fi

  if [[ -d "$site_dir" ]]; then
    echo -e "${YELLOW}${WARNING} Website '$domain' already exists.${NC}"
    confirm_action "Do you want to reset it before migration?"
    if [[ $? -ne 0 ]]; then
      echo -e "${YELLOW}${WARNING} Migration cancelled.${NC}"
      return 0
    fi

    echo -e "${CYAN}🔄 Removing existing files at ${web_root}...${NC}"
    rm -rf "$web_root"
    mkdir -p "$web_root"
    echo -e "${GREEN}${CHECKMARK} Existing files removed.${NC}"
  else
    echo -e "${YELLOW}${WARNING} Website '$domain' does not exist yet.${NC}"
    confirm_action "Do you want to create it before migration?"
    if [[ $? -ne 0 ]]; then
      echo -e "${YELLOW}${WARNING} Migration cancelled.${NC}"
      return 0
    fi

    bash "$MENU_DIR/website/website_create_menu.sh"
  fi

  # Extract source
  echo -e "${CYAN}📦 Extracting source files to $web_root${NC}"
  if [[ "$archive_file" == *.zip ]]; then
    unzip -q "$archive_file" -d "$web_root"
  else
    tar -xzf "$archive_file" -C "$web_root"
  fi

  # Import SQL
  echo -e "${CYAN}🧠 Importing database...${NC}"
  bash "$CLI_DIR/database_import.sh" --domain="$domain" --backup_file="$sql_file"

  # Check prefix in DB
  echo -e "${CYAN}🔍 Checking table prefix...${NC}"
  read db_name db_user db_pass < <(db_fetch_env "$domain") || return 1
  local prefix
  prefix=$(docker exec --env MYSQL_PWD="$db_pass" "$mariadb_container" \
    mysql -u "$db_user" "$db_name" -e "SHOW TABLES;" \
    | tail -n +2 | awk -F_ '/_/ {print $1"_" ; exit}')
  # Update wp-config.php
  local config_file="$web_root/wp-config.php"
  if [[ -f "$config_file" ]]; then
    local config_prefix
    config_prefix=$(grep "table_prefix" "$config_file" | grep -o "'[^']*'" | sed "s/'//g")

    if [[ "$prefix" != "$config_prefix" ]]; then
      echo -e "${YELLOW}${WARNING} Detected table prefix mismatch: DB uses '$prefix' but wp-config.php uses '$config_prefix'. Updating...${NC}"
      sedi "s/\\$table_prefix *= *'[^']*'/\\$table_prefix = '$prefix'/" "$config_file"
      echo -e "${CHECKMARK}${GREEN} Table prefix updated in wp-config.php to: $prefix${NC}"
    fi

    echo -e "${CYAN}✏️ Updating database credentials in wp-config.php...${NC}"
    local db_user db_pass
    read db_name db_user db_pass < <(db_fetch_env "$domain") || return 1

    sedi "s/define( *'DB_NAME'.*/define('DB_NAME', '$db_name');/" "$config_file"
    sedi "s/define( *'DB_USER'.*/define('DB_USER', '$db_user');/" "$config_file"
    sedi "s/define( *'DB_PASSWORD'.*/define('DB_PASSWORD', '$db_pass');/" "$config_file"
    echo -e "${GREEN}${CHECKMARK} wp-config.php has been updated with new database credentials.${NC}"
  else
    echo -e "${RED}${CROSSMARK} wp-config.php not found at $config_file. Cannot update DB credentials.${NC}"
    return 1
  fi

  # Install SSL (optional)
  echo -e "${CYAN}🔐 SSL Installation (Let's Encrypt)${NC}"
  echo -e "${YELLOW}To install SSL, the domain '${domain}' must point to the server IP: ${server_ip}${NC}"
  confirm_action "Do you want to install a free SSL certificate from Let's Encrypt now?"
  if [[ $? -eq 0 ]]; then
    echo -e "${CYAN}Installing Let's Encrypt SSL for $domain...${NC}"
    bash "$CLI_DIR/ssl_install_letsencrypt.sh" --domain="$domain"
  else
    echo -e "${YELLOW} Skipped SSL installation.${NC}"
  fi

  # Check DNS
  echo -e "${CYAN}🌐 Checking if $domain is pointing to this server IP...${NC}"
  local server_ip
  server_ip=$(curl -s ifconfig.me)
  if ! dig +short "$domain" | grep -q "$server_ip"; then
    echo -e "${YELLOW}${WARNING} Domain does NOT point to this server ($server_ip). Please update your DNS settings.${NC}"
  else
    echo -e "${GREEN}${CHECKMARK} Domain points to server IP: $server_ip${NC}"
  fi

  echo ""
  echo -e "${GREEN} Migration completed for '$domain'. Please ensure DNS is correctly configured.${NC}"
  echo -e "${YELLOW}${INFO} To optimize website performance, please run ${CYAN}wpdocker${NC} and choose option ${GREEN}7) WordPress Cache Management${NC} from the menu.${NC}"
  
}