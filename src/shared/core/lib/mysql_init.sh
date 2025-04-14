core_mysql_calculate_config() {
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

core_mysql_apply_config() {
    if [[ -f "$MYSQL_CONFIG_FILE" ]]; then
        print_msg warning "⚠️ MySQL config already exists at $MYSQL_CONFIG_FILE → skip generating."
        return 0
    fi

    print_msg info "Generating MySQL config file at: $MYSQL_CONFIG_FILE"

    local config_values
    config_values="$(core_mysql_calculate_config)"
    IFS=',' read -r max_connections query_cache_size innodb_buffer_pool_size \
        innodb_log_file_size table_open_cache thread_cache_size <<<"$config_values"

    cat >"$MYSQL_CONFIG_FILE" <<EOF
[mysqld]
max_connections = $max_connections
query_cache_size = ${query_cache_size}M
innodb_buffer_pool_size = ${innodb_buffer_pool_size}M
innodb_log_file_size = ${innodb_log_file_size}M
table_open_cache = $table_open_cache
thread_cache_size = $thread_cache_size
EOF

    print_msg success "✅ MySQL config generated successfully."
}

core_mysql_check_running() {
    # return true if the container is running
    docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER_NAME" 2>/dev/null | grep -q true
}

core_mysql_generate_compose() {
    local compose_file="$MYSQL_DIR/docker-compose.yml"
    local template_file="$TEMPLATES_DIR/mysql-docker-compose.yml.template"

    if [[ -f "$compose_file" ]]; then
        debug_log "MySQL docker-compose.yml already exists at: $compose_file → skip generation."
        return 0
    fi

    if [[ ! -f "$template_file" ]]; then
        print_msg error "❌ Missing MySQL docker-compose template at: $template_file"
        return 1
    fi

    # Đảm bảo file .config.json tồn tại
    json_create_if_not_exists "$JSON_CONFIG_FILE"
    debug_log "[core_mysql_generate_compose] JSON CONFIG: $JSON_CONFIG_FILE"

    # Kiểm tra & sinh root password nếu chưa có
    if ! json_key_exists '.mysql.root_password' "$JSON_CONFIG_FILE"; then
        local generated_root_pass
        generated_root_pass="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)"
        json_set_string_value '.mysql.root_password' "$generated_root_pass" "$JSON_CONFIG_FILE"
        print_msg info "✅ Generated new MySQL root password and saved to .config.json"
    fi

    local mysql_root_pass
    mysql_root_pass=$(json_get_value '.mysql.root_password' "$JSON_CONFIG_FILE")

    print_msg info "Generating docker-compose.yml for MySQL from template..."

    cp "$template_file" "$compose_file.tmp"
    sedi "s|\${mysql_container}|$MYSQL_CONTAINER_NAME|g" "$compose_file.tmp"
    sedi "s|\${mysql_image}|$MYSQL_IMAGE|g" "$compose_file.tmp"
    sedi "s|\${mysql_volume_name}|$MYSQL_VOLUME_NAME|g" "$compose_file.tmp"
    sedi "s|\${mysql_root_passwd}|$mysql_root_pass|g" "$compose_file.tmp"
    mv "$compose_file.tmp" "$compose_file"

    print_msg success "✅ Generated docker-compose.yml at: $compose_file"
}

core_mysql_start() {
    local compose_file
    compose_file="$MYSQL_DIR/docker-compose.yml"
    if core_mysql_check_running; then
        print_msg success "MySQL container \"$MYSQL_CONTAINER_NAME\" is already running."
        return 0
    fi

    print_msg info "Starting MySQL container: $MYSQL_CONTAINER_NAME"

    core_mysql_apply_config

    # Kiểm tra tập tin docker-compose.yml và tạo ra nếu chưa có
    core_mysql_generate_compose

    # Khởi động container bằng docker compose -f
    docker compose -f "$compose_file" up -d

    print_msg success "✅ MySQL container \"$MYSQL_CONTAINER_NAME\" has been started."
}
