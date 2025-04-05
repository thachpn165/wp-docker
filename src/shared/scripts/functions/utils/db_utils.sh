#!/bin/bash
calculate_mariadb_config() {
    local total_ram=$(get_total_ram)
    local total_cpu=$(get_total_cpu)

    # Optimize configuration based on system resources
    max_connections=$((total_ram / 4))  # Maximum connections (1/4 RAM)
    query_cache_size=32  # Query cache size (MB)
    innodb_buffer_pool_size=$((total_ram / 2))  # InnoDB Buffer Pool = 1/2 RAM
    innodb_log_file_size=$((innodb_buffer_pool_size / 4))  # InnoDB Log File = 1/4 Buffer Pool
    table_open_cache=$((total_ram * 8))  # Table open cache
    thread_cache_size=$((total_cpu * 8))  # Thread cache

    # Set reasonable minimum and maximum values
    max_connections=$((max_connections > 100 ? max_connections : 100))
    innodb_buffer_pool_size=$((innodb_buffer_pool_size > 256 ? innodb_buffer_pool_size : 256))
    innodb_log_file_size=$((innodb_log_file_size > 64 ? innodb_log_file_size : 64))
    table_open_cache=$((table_open_cache > 400 ? table_open_cache : 400))
    thread_cache_size=$((thread_cache_size > 16 ? thread_cache_size : 16))

    # Return calculated values
    echo "$max_connections,$query_cache_size,$innodb_buffer_pool_size,$innodb_log_file_size,$table_open_cache,$thread_cache_size"
}

apply_mariadb_config() {
    local mariadb_conf_path="$1"

    # If file exists, remove to create new
    if [ -f "$mariadb_conf_path" ]; then
        rm -f "$mariadb_conf_path"
    fi

    # Get optimal parameters
    IFS=',' read -r max_connections query_cache_size innodb_buffer_pool_size innodb_log_file_size table_open_cache thread_cache_size <<< "$(calculate_mariadb_config)"

    # Set fixed value for `innodb_io_capacity = 1500`
    innodb_io_capacity=1500

    # Create configuration file
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

    echo "${CHECKMARK} Created optimized MariaDB configuration at $mariadb_conf_path"
}

# Function to check if database container is running
is_mariadb_running() {
    local container_name="$1-mariadb"
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Function to import database (restore from backup)
db_import_database() {
    local domain="$1"
    local db_user="$2"
    local db_password="$3"
    local db_name="$4"
    local backup_file="$5"
    
    if ! is_mariadb_running "$domain"; then
        echo "${CROSSMARK} MariaDB container for site '$domain' is not running. Please check!"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo "${CROSSMARK} Backup file does not exist: $backup_file"
        return 1
    fi
    
    echo "Restoring database: $db_name for site: $domain from file: $backup_file..."
    docker exec -i ${domain}-mariadb mysql -u$db_user -p$db_password $db_name < "$backup_file"
    echo "${CHECKMARK} Database import completed!"
}

# Function to fetch database variable from .env file
db_fetch_env() {
    local domain="$1"
    local env_file="$SITES_DIR/$domain/.env"

    if [[ ! -f "$env_file" ]]; then
        echo "${CROSSMARK} .env file not found for $domain at $env_file"
        return 1
    fi

    local db_name=$(fetch_env_variable "$env_file" "MYSQL_DATABASE")
    local db_user=$(fetch_env_variable "$env_file" "MYSQL_USER")
    local db_pass=$(fetch_env_variable "$env_file" "MYSQL_PASSWORD")

    if [[ -z "$db_name" || -z "$db_user" || -z "$db_pass" ]]; then
        echo "${CROSSMARK} Missing database credentials in .env for $domain"
        return 1
    fi

    # Return the values
    echo "$db_name $db_user $db_pass"
}

# Function to get database name
db_get_name() {
    local domain="$1"
    
    local db_info
    if ! db_info=$(db_fetch_env "$domain"); then
        echo -e "${RED}${CROSSMARK} Unable to get database info for $domain${NC}" >&2
        return 1
    fi

    local db_name db_user db_pass
    read -r db_name db_user db_pass <<< "$db_info"

    echo "$db_name"
}