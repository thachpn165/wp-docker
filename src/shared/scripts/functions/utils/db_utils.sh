#!/bin/bash
# This function calculates optimal MariaDB configuration values based on the system's
# total RAM and CPU cores. It outputs a comma-separated list of the calculated values.
#
# Outputs:
#   A comma-separated string containing the following MariaDB configuration values:
#     - max_connections: Maximum number of connections (calculated as total RAM / 4, with a minimum of 100).
#     - query_cache_size: Query cache size (fixed at 32 MB).
#     - innodb_buffer_pool_size: Size of the InnoDB buffer pool (calculated as total RAM / 2, with a minimum of 256 MB).
#     - innodb_log_file_size: Size of the InnoDB log file (calculated as innodb_buffer_pool_size / 4, with a minimum of 64 MB).
#     - table_open_cache: Number of table cache entries (calculated as total RAM * 8, with a minimum of 400).
#     - thread_cache_size: Number of thread cache entries (calculated as total CPU cores * 8, with a minimum of 16).
#
# Dependencies:
#   - get_total_ram: A function that returns the total RAM in MB.
#   - get_total_cpu: A function that returns the total number of CPU cores.
#   - debug_log: A function used for logging debug messages.
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

# Applies the MariaDB configuration by generating a configuration file with optimized settings.
#
# Arguments:
#   $1 - The file path where the MariaDB configuration will be written.
#
# Behavior:
#   - If the specified configuration file already exists, it will be removed.
#   - Reads optimized MariaDB settings (e.g., max_connections, query_cache_size, etc.)
#     from the `calculate_mariadb_config` function.
#   - Writes the settings to the specified configuration file in the proper MariaDB format.
#
# Configuration Parameters:
#   - character-set-server: Sets the character set to utf8mb4.
#   - collation-server: Sets the collation to utf8mb4_unicode_ci.
#   - max_connections: Maximum number of connections.
#   - query_cache_size: Size of the query cache in MB.
#   - innodb_buffer_pool_size: Size of the InnoDB buffer pool in MB.
#   - innodb_log_file_size: Size of the InnoDB log file in MB.
#   - innodb_flush_log_at_trx_commit: Controls the flushing behavior of the log.
#   - innodb_lock_wait_timeout: Timeout in seconds for InnoDB lock waits.
#   - table_open_cache: Number of open tables for all threads.
#   - thread_cache_size: Number of threads to cache.
#   - innodb_io_capacity: I/O capacity for InnoDB.
#
# Outputs:
#   - Creates or overwrites the MariaDB configuration file at the specified path.
#
# Example:
#   apply_mariadb_config "/etc/mysql/mariadb.conf.d/50-server.cnf"
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

# Function to check if database container is running
is_mariadb_running() {
  local container_name="$(fetch_env_variable "$SITES_DIR/$1/.env" "CONTAINER_DB")"
  debug_log "[MARIADB] Checking if container is running: $container_name"
  docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Function to import database (restore from backup)
db_import_database() {
  local domain="$1" db_user="$2" db_password="$3" db_name="$4" backup_file="$5"

  if ! is_mariadb_running "$domain"; then
    print_and_debug error "$(printf "$ERROR_MARIADB_NOT_RUNNING" "$domain")"
    return 1
  fi

  if [[ ! -f "$backup_file" ]]; then
    print_and_debug error "$(printf "$ERROR_BACKUP_FILE_NOT_FOUND" "$backup_file")"
    return 1
  fi

  print_msg run "$(printf "$STEP_DB_IMPORTING" "$db_name" "$domain")"

  docker exec -i --env MYSQL_PWD="$db_password" "${domain}-mariadb" \
    mysql -u"$db_user" "$db_name" < "$backup_file"

  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_DB_IMPORTED"
  else
    print_and_debug error "$(printf "$ERROR_DB_IMPORT_FAILED" "$backup_file")"
    return 1
  fi
}

# Fetch all DB credentials from .env
db_fetch_env() {
    local domain="$1"
    local env_file="$SITES_DIR/$domain/.env"

    if [[ ! -f "$env_file" ]]; then
        print_and_debug error "$(printf "$ERROR_ENV_NOT_FOUND_FOR_SITE" "$domain" "$env_file")"
        return 1
    fi

    local db_name db_user db_pass
    db_name=$(fetch_env_variable "$env_file" "MYSQL_DATABASE")
    db_user=$(fetch_env_variable "$env_file" "MYSQL_USER")
    db_pass=$(fetch_env_variable "$env_file" "MYSQL_PASSWORD")

    if [[ -z "$db_name" || -z "$db_user" || -z "$db_pass" ]]; then
        print_and_debug error "$(printf "$ERROR_DB_ENV_MISSING" "$domain")"
        return 1
    fi

    debug_log "[DB FETCH] domain=$domain, db_name=$db_name, db_user=$db_user"
    echo "$db_name $db_user $db_pass"
}

# Get DB name only
db_get_name() {
    local domain="$1"
    local db_info

    if ! db_info=$(db_fetch_env "$domain"); then return 1; fi
    local db_name
    read -r db_name _ _ <<< "$db_info"
    debug_log "[db_get_name] domain=$domain → db_name=$db_name"
    echo "$db_name"
}

# Get DB user only
db_get_user() {
    local domain="$1"
    local db_info

    if ! db_info=$(db_fetch_env "$domain"); then return 1; fi
    local _ db_user _
    read -r _ db_user _ <<< "$db_info"
    debug_log "[db_get_user] domain=$domain → db_user=$db_user"
    echo "$db_user"
}

# Get database container name from .env
db_get_container() {
    local domain="$1"
    local env_file="$SITES_DIR/$domain/.env"

    if [[ ! -f "$env_file" ]]; then
        print_and_debug error "$(printf "$ERROR_ENV_NOT_FOUND_FOR_SITE" "$domain" "$env_file")"
        return 1
    fi

    local container_name
    container_name=$(fetch_env_variable "$env_file" "CONTAINER_DB")
    if [[ -z "$container_name" ]]; then
        print_and_debug error "$(printf "$ERROR_DB_CONTAINER_NOT_FOUND" "$domain")"
        return 1
    fi

    debug_log "[DB CONTAINER] domain=$domain → container=$container_name"
    echo "$container_name"
}