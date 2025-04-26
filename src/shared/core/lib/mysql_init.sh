# ============================================
# File: mysql_init.sh
# Description:
#   - This script contains functions to manage MySQL configuration and container setup.
#   - Functions:
#       1. core_mysql_calculate_config:
#           - Parameters: None
#           - Description: Calculates optimized MySQL config values based on system resources.
#       2. core_mysql_apply_config:
#           - Parameters: None
#           - Description: Generates the `my.cnf` MySQL configuration file with system-optimized values.
#       3. core_mysql_generate_compose:
#           - Parameters: None
#           - Description: Creates docker-compose.yml for MySQL container using a template.
#       4. core_mysql_start:
#           - Parameters: None
#           - Description: Starts the MySQL container using docker-compose.
# ============================================

core_mysql_calculate_config() {
    local total_ram total_cpu
    total_ram=$(get_total_ram)
    total_cpu=$(get_total_cpu)

    max_connections=$((total_ram / 4))
    query_cache_size=32
    innodb_buffer_pool_size=$((total_ram / 2))
    innodb_log_file_size=$((innodb_buffer_pool_size / 6))
    table_open_cache=$((total_ram * 8))
    thread_cache_size=$((total_cpu * 8))

    max_connections=$((max_connections > 100 ? max_connections : 100))
    innodb_buffer_pool_size=$((innodb_buffer_pool_size > 256 ? innodb_buffer_pool_size : 256))
    innodb_log_file_size=$((innodb_log_file_size > 64 ? innodb_log_file_size : 64))
    table_open_cache=$((table_open_cache > 400 ? table_open_cache : 400))
    thread_cache_size=$((thread_cache_size > 16 ? thread_cache_size : 16))

    echo "$max_connections,$query_cache_size,$innodb_buffer_pool_size,$innodb_log_file_size,$table_open_cache,$thread_cache_size"
}

core_mysql_apply_config() {
    if [[ -f "$MYSQL_CONFIG_FILE" ]]; then
        print_and_debug info "$WARNING_MYSQL_CONFIG_EXISTS: $MYSQL_CONFIG_FILE"
        return 0
    fi

    print_msg info "$INFO_MYSQL_GENERATING_CONFIG $MYSQL_CONFIG_FILE"

    local config_values
    config_values="$(core_mysql_calculate_config)"
    debug_log "MySQL config values: $config_values"
    IFS=',' read -r max_connections query_cache_size innodb_buffer_pool_size \
        innodb_log_file_size table_open_cache thread_cache_size <<<"$config_values"

    _is_directory_exist "$(dirname "$MYSQL_CONFIG_FILE")" true
    cat >"$MYSQL_CONFIG_FILE" <<EOF
[mysqld]
max_connections = $max_connections
query_cache_size = ${query_cache_size}M
innodb_buffer_pool_size = ${innodb_buffer_pool_size}M
innodb_log_file_size = ${innodb_log_file_size}M
table_open_cache = $table_open_cache
thread_cache_size = $thread_cache_size
EOF

    print_msg success "$SUCCESS_MYSQL_CONFIG_GENERATED"
}

core_mysql_generate_compose() {
    local compose_file="$MYSQL_DIR/docker-compose.yml"
    local template_file="$TEMPLATES_DIR/mysql-docker-compose.yml.template"

    if [[ -f "$compose_file" ]]; then
        print_and_debug info "$WARNING_MYSQL_DOCKER_COMPOSE_EXISTS: $compose_file"
        return 0
    fi

    if [[ ! -f "$template_file" ]]; then
        print_and_debug error "$ERROR_MYSQL_MISSING_DOCKER_TEMPLATE: $template_file"
        return 1
    fi

    json_create_if_not_exists "$JSON_CONFIG_FILE"
    debug_log "[core_mysql_generate_compose] JSON CONFIG: $JSON_CONFIG_FILE"

    if ! json_key_exists '.mysql.root_password' "$JSON_CONFIG_FILE"; then
        local generated_root_pass
        generated_root_pass="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)"
        json_set_string_value '.mysql.root_password' "$generated_root_pass" "$JSON_CONFIG_FILE"
        print_msg success "$SUCCESS_MYSQL_ROOT_PASSWORD_GENERATED: $generated_root_pass"
    fi

    local mysql_root_pass
    mysql_root_pass=$(json_get_value '.mysql.root_password' "$JSON_CONFIG_FILE")
    mkdir -p "$(dirname "$compose_file")"
    _is_directory_exist "$(dirname "$compose_file")" true
    print_msg step "$INFO_MYSQL_GENERATING_DOCKER_COMPOSE"

    cp "$template_file" "$compose_file.tmp"
    sedi "s|\${mysql_container}|$MYSQL_CONTAINER_NAME|g" "$compose_file.tmp"
    sedi "s|\${mysql_image}|$MYSQL_IMAGE|g" "$compose_file.tmp"
    sedi "s|\${mysql_volume_name}|$MYSQL_VOLUME_NAME|g" "$compose_file.tmp"
    sedi "s|\${mysql_root_passwd}|$mysql_root_pass|g" "$compose_file.tmp"
    sedi "s|\${docker_network}|$DOCKER_NETWORK|g" "$compose_file.tmp"
    mv "$compose_file.tmp" "$compose_file"

    print_msg success "$SUCCESS_MYSQL_GENERATED_DOCKER_COMPOSE"
}

core_mysql_start() {
    local compose_file="$MYSQL_DIR/docker-compose.yml"

    core_mysql_apply_config
    core_mysql_generate_compose

    if core_mysql_check_running; then
        print_msg success "$SUCCESS_MYSQL_CONTAINER_RUNNING: $MYSQL_CONTAINER_NAME"
        return 0
    fi

    print_msg step "$INFO_MYSQL_STARTING_CONTAINER: $MYSQL_CONTAINER_NAME"

    docker compose -f "$compose_file" up -d

    print_msg success "$SUCCESS_MYSQL_CONTAINER_STARTED: $MYSQL_CONTAINER_NAME"
}
