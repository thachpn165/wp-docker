#!/bin/bash

# ==============================
# WordPress Setup & Utilities
# ==============================

# =====================================
# calculate_mariadb_config: Calculate optimized MariaDB config values
# Based on total RAM and CPU cores
# Outputs:
#   Comma-separated values: max_connections, query_cache_size, buffer_pool_size, etc.
# =====================================
calculate_mariadb_config() {
  local total_ram
  total_ram=$(get_total_ram)
  local total_cpu
  total_cpu=$(get_total_cpu)

  max_connections=$((total_ram / 4))
  query_cache_size=32
  innodb_buffer_pool_size=$((total_ram / 2))
  innodb_log_file_size=$((innodb_buffer_pool_size / 8))
  table_open_cache=$((total_ram * 8))
  thread_cache_size=$((total_cpu * 8))

  # Ensure minimum values
  max_connections=$((max_connections > 100 ? max_connections : 100))
  innodb_buffer_pool_size=$((innodb_buffer_pool_size > 256 ? innodb_buffer_pool_size : 256))
  innodb_log_file_size=$((innodb_log_file_size > 64 ? innodb_log_file_size : 64))
  table_open_cache=$((table_open_cache > 400 ? table_open_cache : 400))
  thread_cache_size=$((thread_cache_size > 16 ? thread_cache_size : 16))

  echo "$max_connections,$query_cache_size,$innodb_buffer_pool_size,$innodb_log_file_size,$table_open_cache,$thread_cache_size"
}

# =====================================
# apply_mariadb_config: Generate MariaDB config file using calculated values
# Parameters:
#   $1 - mariadb_conf_path: Path to write the MariaDB config file
# =====================================
apply_mariadb_config() {
  local mariadb_conf_path="$1"

  if [[ -f "$mariadb_conf_path" ]]; then
    rm -f "$mariadb_conf_path"
  fi

  IFS=',' read -r max_connections query_cache_size innodb_buffer_pool_size innodb_log_file_size table_open_cache thread_cache_size <<< "$(calculate_mariadb_config)"

  local innodb_io_capacity=1500

  cat > "$mariadb_conf_path" <<EOF
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = $max_connections
query_cache_size = ${query_cache_size}M
innodb_buffer_pool_size = ${innodb_buffer_pool_size}M
innodb_log_file_size = ${innodb_log_file_size}M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
table_open_cache = $table_open_cache
thread_cache_size = $thread_cache_size
innodb_io_capacity = $innodb_io_capacity
EOF

  print_msg success "$(printf "$SUCCESS_MARIADB_CONFIG_CREATED" "$mariadb_conf_path")"
}

# =====================================
# is_mariadb_running: Check if MariaDB container is running for a domain
# Parameters:
#   $1 - domain
# Returns:
#   0 if running, 1 if not
# =====================================
is_mariadb_running() {
  local domain="$1"
  local container_name
  container_name=$(json_get_site_value "$domain" "CONTAINER_DB")
  debug_log "[MARIADB] Checking if container is running: $container_name"
  docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# =====================================
# db_import_database: Import SQL file into MariaDB container
# Parameters:
#   $1 - domain
#   $2 - db_user
#   $3 - db_password
#   $4 - db_name
#   $5 - backup_file: SQL file path
# =====================================
db_import_database() {
  local domain="$1" db_user="$2" db_password="$3" db_name="$4" backup_file="$5"
  local container_name
  container_name=$(json_get_site_value "$domain" "CONTAINER_DB")

  if ! is_mariadb_running "$domain"; then
    print_and_debug error "$(printf "$ERROR_MARIADB_NOT_RUNNING" "$domain")"
    return 1
  fi

  if [[ ! -f "$backup_file" ]]; then
    print_and_debug error "$(printf "$ERROR_BACKUP_FILE_NOT_FOUND" "$backup_file")"
    return 1
  fi

  print_msg run "$(printf "$STEP_DB_IMPORTING" "$db_name" "$domain")"

  docker exec -i --env MYSQL_PWD="$db_password" "$container_name" \
    mysql -u"$db_user" "$db_name" < "$backup_file"

  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_DB_IMPORTED"
  else
    print_and_debug error "$(printf "$ERROR_DB_IMPORT_FAILED" "$backup_file")"
    return 1
  fi
}

# =====================================
# db_fetch_env: Retrieve DB credentials from .config.json
# Parameters:
#   $1 - domain
# Outputs:
#   Echoes "db_name db_user db_pass"
# =====================================
db_fetch_env() {
  local domain="$1"
  local db_name db_user db_pass

  db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
  db_user=$(json_get_site_value "$domain" "MYSQL_USER")
  db_pass=$(json_get_site_value "$domain" "MYSQL_PASSWORD")

  if [[ -z "$db_name" || -z "$db_user" || -z "$db_pass" ]]; then
    print_and_debug error "$(printf "$ERROR_DB_ENV_MISSING" "$domain")"
    return 1
  fi

  debug_log "[DB FETCH] domain=$domain, db_name=$db_name, db_user=$db_user"
  echo "$db_name $db_user $db_pass"
}

# =====================================
# db_get_name: Get database name for a domain
# Parameters:
#   $1 - domain
# Outputs:
#   Database name
# =====================================
db_get_name() {
  local domain="$1"
  local db_name
  db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
  debug_log "[db_get_name] domain=$domain → db_name=$db_name"
  echo "$db_name"
}

# =====================================
# db_get_user: Get database user for a domain
# Parameters:
#   $1 - domain
# Outputs:
#   Database user
# =====================================
db_get_user() {
  local domain="$1"
  local db_user
  db_user=$(json_get_site_value "$domain" "MYSQL_USER")
  debug_log "[db_get_user] domain=$domain → db_user=$db_user"
  echo "$db_user"
}

# =====================================
# db_get_container: Get database container name for a domain
# Parameters:
#   $1 - domain
# Outputs:
#   Container name
# =====================================
db_get_container() {
  local domain="$1"
  local container_name
  container_name=$(json_get_site_value "$domain" "CONTAINER_DB")

  if [[ -z "$container_name" ]]; then
    print_and_debug error "$(printf "$ERROR_DB_CONTAINER_NOT_FOUND" "$domain")"
    return 1
  fi

  debug_log "[DB CONTAINER] domain=$domain → container=$container_name"
  echo "$container_name"
}