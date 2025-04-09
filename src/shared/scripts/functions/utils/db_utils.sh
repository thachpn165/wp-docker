#!/bin/bash

# ==============================
# WordPress Setup & Utilities
# ==============================

calculate_mariadb_config() {
  local total_ram=$(get_total_ram)
  local total_cpu=$(get_total_cpu)
  max_connections=$((total_ram / 4))
  query_cache_size=32
  innodb_buffer_pool_size=$((total_ram / 2))
  innodb_log_file_size=$((innodb_buffer_pool_size / 4))
  table_open_cache=$((total_ram * 8))
  thread_cache_size=$((total_cpu * 8))

  max_connections=$((max_connections > 100 ? max_connections : 100))
  innodb_buffer_pool_size=$((innodb_buffer_pool_size > 256 ? innodb_buffer_pool_size : 256))
  innodb_log_file_size=$((innodb_log_file_size > 64 ? innodb_log_file_size : 64))
  table_open_cache=$((table_open_cache > 400 ? table_open_cache : 400))
  thread_cache_size=$((thread_cache_size > 16 ? thread_cache_size : 16))

  echo "$max_connections,$query_cache_size,$innodb_buffer_pool_size,$innodb_log_file_size,$table_open_cache,$thread_cache_size"
}

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

is_mariadb_running() {
  local domain="$1"
  local container_name=$(json_get_site_value "$domain" "CONTAINER_DB")
  debug_log "[MARIADB] Checking if container is running: $container_name"
  docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

db_import_database() {
  local domain="$1" db_user="$2" db_password="$3" db_name="$4" backup_file="$5"

  local container_name=$(json_get_site_value "$domain" "CONTAINER_DB")

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

db_fetch_env() {
  local domain="$1"
  local db_name db_user db_pass

  # Truy xuất đúng thông tin của domain từ .config.json
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

db_get_name() {
  local domain="$1"
  local db_name
  db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
  debug_log "[db_get_name] domain=$domain → db_name=$db_name"
  echo "$db_name"
}

db_get_user() {
  local domain="$1"
  local db_user
  db_user=$(json_get_site_value "$domain" "MYSQL_USER")
  debug_log "[db_get_user] domain=$domain → db_user=$db_user"
  echo "$db_user"
}

db_get_container() {
  local domain="$1"
  local container_name=$(json_get_site_value "$domain" "CONTAINER_DB")

  if [[ -z "$container_name" ]]; then
    print_and_debug error "$(printf "$ERROR_DB_CONTAINER_NOT_FOUND" "$domain")"
    return 1
  fi

  debug_log "[DB CONTAINER] domain=$domain → container=$container_name"
  echo "$container_name"
}
