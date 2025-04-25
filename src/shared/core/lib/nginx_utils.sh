# =============================================
# 🔧 Function: nginx_init_docker_compose
# Description: Generate docker-compose.yml from template if not exists
# =============================================
nginx_init_docker_compose() {
    local compose_file="$NGINX_PROXY_DIR/docker-compose.yml"
    local template_file="$TEMPLATES_DIR/nginx-docker-compose.yml.template"

    debug_log "[nginx_init_docker_compose] Checking template: $template_file"
    debug_log "[nginx_init_docker_compose] Target file: $compose_file"

    if [[ ! -f "$template_file" ]]; then
        print_msg error "❌ Missing template: $template_file"
        return 1
    fi

    cp "$template_file" "$compose_file.tmp"
    sedi "s|\${nginx_container_name}|$NGINX_PROXY_CONTAINER|g" "$compose_file.tmp"
    sedi "s|\${docker_network}|$DOCKER_NETWORK|g" "$compose_file.tmp"
    mv "$compose_file.tmp" "$compose_file"
    print_msg success "$SUCCESS_NGINX_COMPOSE_GENERATED: $compose_file"
}

# =============================================
# 🚀 Function: nginx_init
# Description: Initialize and ensure NGINX proxy is correctly set up
# =============================================
nginx_init() {
    _is_directory_exist "$NGINX_PROXY_DIR" true

    print_msg step "$MSG_CHECKING_CONTAINER: $NGINX_PROXY_CONTAINER"

    if _is_container_running "$NGINX_PROXY_CONTAINER"; then
        debug_log "[nginx_init] ✅ Container $NGINX_PROXY_CONTAINER is running"
        [[ ! -f "$NGINX_PROXY_DIR/docker-compose.yml" ]] && nginx_init_docker_compose
        return 0
    fi

    if [[ ! -f "$NGINX_PROXY_DIR/docker-compose.yml" ]] && docker ps -a --format '{{.Names}}' | grep -q "^${NGINX_PROXY_CONTAINER}$"; then
        print_msg warning "⚠️ docker-compose.yml not found but container $NGINX_PROXY_CONTAINER exists. Removing container..."
        docker rm -f "$NGINX_PROXY_CONTAINER"
    fi

    [[ ! -f "$NGINX_PROXY_DIR/docker-compose.yml" ]] && nginx_init_docker_compose

    docker volume create wpdocker_fastcgi_cache_data >/dev/null
    docker compose -f "$NGINX_PROXY_DIR/docker-compose.yml" up -d --force-recreate
    print_msg success "$MSG_CONTAINER_READY: $NGINX_PROXY_CONTAINER"
}

# =====================================
# nginx_add_mount_docker: Add volume mount to docker-compose.override.yml for a domain
# Parameters:
#   $1 - domain name
# Behavior:
#   - Creates override file if not exists
#   - Appends mount paths for WordPress source and logs
# =====================================
nginx_add_mount_docker() {
    local domain="$1"
    local OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"

    # If in TEST_MODE, use mock file
    if [[ "$TEST_MODE" == true ]]; then
        OVERRIDE_FILE="/tmp/mock-docker-compose.override.yml"
    fi

    local MOUNT_ENTRY="      - ../../../../sites/$domain/wordpress:/var/www/$domain"
    local MOUNT_LOGS="      - ../../../../sites/$domain/logs:/var/www/logs/$domain"

    if [ ! -f "$OVERRIDE_FILE" ]; then
        print_msg info "$INFO_DOCKER_NGINX_CREATING_DOCKER_COMPOSE_OVERRIDE"
        cat >"$OVERRIDE_FILE" <<EOF
services:
  $NGINX_PROXY_CONTAINER:
    volumes:
$MOUNT_ENTRY
$MOUNT_LOGS
EOF
        print_msg success "$SUCCESS_DOCKER_NGINX_CREATE_DOCKER_COMPOSE_OVERRIDE"
        return
    fi

    # Check and add MOUNT_ENTRY if needed
    if ! grep -Fxq "$MOUNT_ENTRY" "$OVERRIDE_FILE"; then
        if ! echo "$MOUNT_ENTRY" | tee -a "$OVERRIDE_FILE" >/dev/null; then
            print_msg error "$ERROR_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_ENTRY"
            nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
            return 1
        fi
        print_msg success "$SUCCESS_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_ENTRY"
        nginx_restart
    else
        print_msg skip "$SKIP_DOCKER_NGINX_MOUNT_VOLUME_EXIST: $MOUNT_ENTRY"
    fi

    # Check and add MOUNT_LOGS if needed
    if ! grep -Fxq "$MOUNT_LOGS" "$OVERRIDE_FILE"; then
        if ! echo "$MOUNT_LOGS" | tee -a "$OVERRIDE_FILE" >/dev/null; then
            print_msg error "$ERROR_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_LOGS"
            nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
            return 1
        fi
        print_msg success "$SUCCESS_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_LOGS"
        nginx_restart
    else
        print_msg skip "$SKIP_DOCKER_NGINX_MOUNT_VOLUME_EXIST: $MOUNT_LOGS"
    fi
}

# =====================================
# nginx_remove_mount_docker: Remove volume mounts from override file
# Parameters:
#   $1 - override_file path
#   $2 - mount entry path
#   $3 - mount logs path
# Behavior:
#   - Deletes mount entries from file if present
# =====================================
nginx_remove_mount_docker() {
    local override_file="$1"
    local mount_entry="$2"
    local mount_logs="$3"

    local safe_mount_entry="${mount_entry//\//\\\/}"
    safe_mount_entry="${safe_mount_entry//./\\\.}"
    local safe_mount_logs="${mount_logs//\//\\\/}"
    safe_mount_logs="${safe_mount_logs//./\\\.}"

    if [ -f "$override_file" ]; then
        temp_file=$(mktemp)
        grep -vF "$mount_entry" "$override_file" | grep -vF "$mount_logs" >"$temp_file"

        if ! diff "$override_file" "$temp_file" >/dev/null; then
            mv "$temp_file" "$override_file"
            print_msg success "$SUCCESS_DOCKER_NGINX_MOUNT_REMOVED"
            debug_log "Removed mount entries: $mount_entry and $mount_logs"
        else
            rm -f "$temp_file"
            print_msg info "$INFO_DOCKER_NGINX_MOUNT_NOCHANGE"
        fi
    else
        print_msg error "$override_file $ERROR_NOT_EXIST"
    fi
}

# =====================================
# nginx_restart: Restart the NGINX proxy container using Docker Compose
# Behavior:
#   - Runs 'docker compose down' and 'up --force-recreate'
#   - Displays loading and status messages
# =====================================
nginx_restart() {
    print_msg step "$INFO_DOCKER_NGINX_STARTING"
    debug_log "NGINX_PROXY_DIR: $NGINX_PROXY_DIR"
    if [[ ! -d "$NGINX_PROXY_DIR" ]]; then
        print_and_debug error "❌ NGINX_PROXY_DIR does not exist: $NGINX_PROXY_DIR"
        return 1
    fi

    nginx_remove_orphaned_site_conf || return 1

    cd "$NGINX_PROXY_DIR" || {
        print_msg error "$MSG_NOT_FOUND: $NGINX_PROXY_DIR"
        return 1
    }

    run_cmd "docker compose down"
    if [[ $? -ne 0 ]]; then
        print_msg error "$ERROR_DOCKER_NGINX_STOP $NGINX_PROXY_CONTAINER"
        run_cmd "docker ps logs $NGINX_PROXY_CONTAINER"
        return 1
    fi

    run_cmd "docker compose up -d --force-recreate"
    if [[ $? -ne 0 ]]; then
        print_msg error "$ERROR_DOCKER_NGINX_START $NGINX_PROXY_CONTAINER"
        run_cmd "docker ps logs $NGINX_PROXY_CONTAINER"
        return 1
    fi

    cd "$BASE_DIR" || {
        print_msg error "$MSG_NOT_FOUND: $BASE_DIR"
        return 1
    }

    print_msg success "$SUCCESS_DOCKER_NGINX_RESTART"
}

# =====================================
# nginx_reload: Reload NGINX configuration inside the proxy container
# Behavior:
#   - Uses 'nginx -s reload' via docker exec
#   - Shows success or error message
# =====================================
nginx_reload() {
    print_msg step "$INFO_DOCKER_NGINX_RELOADING"

    docker exec "$NGINX_PROXY_CONTAINER" nginx -t
    exit_if_error $? "$ERROR_DOCKER_NGINX_TEST_FAILED"
    run_cmd "docker exec ""$NGINX_PROXY_CONTAINER"" nginx -s reload"
    if [[ $? -ne 0 ]]; then
        print_msg error "$ERROR_DOCKER_NGINX_RELOAD : $NGINX_PROXY_CONTAINER"
        run_cmd "docker ps logs $NGINX_PROXY_CONTAINER"
        stop_loading
        return 1
    fi
    stop_loading
    print_msg success "$SUCCESS_DOCKER_NGINX_RELOAD"
}

wait_for_nginx_container() {
    local timeout=30 # số giây tối đa chờ
    local interval=1 # thời gian giữa mỗi lần kiểm tra
    local waited=0

    print_msg info "⏳ Waiting for container '$NGINX_PROXY_CONTAINER' to start..."

    while ! _is_container_running "$NGINX_PROXY_CONTAINER"; do
        sleep "$interval"
        waited=$((waited + interval))
        if ((waited >= timeout)); then
            print_msg error "❌ Timeout: Container '$NGINX_PROXY_CONTAINER' did not start within $timeout seconds."
            return 1
        fi
    done

    print_msg success "✅ Container '$NGINX_PROXY_CONTAINER' is now running."
    return 0
}

# =============================================
# 🧹 nginx_remove_orphaned_site_conf – Remove orphaned NGINX site configs
# ---------------------------------------------
# Description:
#   - Scan $PROXY_CONF_DIR for *.conf files.
#   - Extract domain name from each filename.
#   - If domain does not exist in .site[], delete the config file.
# =============================================
nginx_remove_orphaned_site_conf() {
    _is_missing_var "$PROXY_CONF_DIR" "PROXY_CONF_DIR" || return 1
    _is_missing_var "$JSON_CONFIG_FILE" "JSON_CONFIG_FILE" || return 1

    local deleted_count=0
    local conf_file domain

    shopt -s nullglob
    for conf_file in "$PROXY_CONF_DIR"/*.conf; do
        domain=$(basename "$conf_file" .conf)

        if ! json_key_exists ".site[\"$domain\"]" "$JSON_CONFIG_FILE"; then
            print_msg warning "⚠️ Orphaned config found: $conf_file → removing"
            remove_file "$conf_file"
            ((deleted_count++))
        fi
    done
    shopt -u nullglob

    if ((deleted_count == 0)); then
        print_msg success "✅ No orphaned NGINX site configs found."
    else
        print_msg success "🧹 Removed $deleted_count broken NGINX config(s)."
    fi
}
