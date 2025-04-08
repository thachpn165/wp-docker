# =====================================
# 🌐 nginx_utils.sh – NGINX Proxy utility functions
# =====================================
nginx_add_mount_docker() {
    local domain="$1"
    local OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"

    # If in TEST_MODE, use mock file
    if [[ "$TEST_MODE" == true ]]; then
        OVERRIDE_FILE="/tmp/mock-docker-compose.override.yml"
    fi

    local MOUNT_ENTRY="      - ../../sites/$domain/wordpress:/var/www/$domain"
    local MOUNT_LOGS="      - ../../sites/$domain/logs:/var/www/logs/$domain"

    if [ ! -f "$OVERRIDE_FILE" ]; then
        print_msg info "$INFO_DOCKER_NGINX_CREATING_DOCKER_COMPOSE_OVERRIDE"
        cat > "$OVERRIDE_FILE" <<EOF #get NGINX_PROXY_CONTAINER from config.sh
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
        if ! echo "$MOUNT_ENTRY" | tee -a "$OVERRIDE_FILE" > /dev/null; then
            print_msg error "$ERROR_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_ENTRY"
            run_cmd nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
            return 1
        fi
        print_msg success "$SUCCESS_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_ENTRY"
    else
        print_msg skip "$SKIP_DOCKER_NGINX_MOUNT_VOLUME_EXIST: $MOUNT_ENTRY"
    fi

    # Check and add MOUNT_LOGS if needed
    if ! grep -Fxq "$MOUNT_LOGS" "$OVERRIDE_FILE"; then
        if ! echo "$MOUNT_LOGS" | tee -a "$OVERRIDE_FILE" > /dev/null; then
            print_msg error "$ERROR_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_LOGS"
            run_cmd nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
            return 1
        fi
        print_msg success "$SUCCESS_DOCKER_NGINX_MOUNT_VOLUME: $MOUNT_LOGS"
    else
        print_msg skip "$SKIP_DOCKER_NGINX_MOUNT_VOLUME_EXIST: $MOUNT_LOGS"
    fi
}

# Helper function to remove entries from docker-compose.override.yml
nginx_remove_mount_docker() {
    local override_file="$1"
    local mount_entry="$2"
    local mount_logs="$3"

    # Escape slashes (/) and dots (.) by replacing them with another delimiter (e.g., #)
    local safe_mount_entry="${mount_entry//\//\\\/}"
    safe_mount_entry="${safe_mount_entry//./\\\.}"
    local safe_mount_logs="${mount_logs//\//\\\/}"
    safe_mount_logs="${safe_mount_logs//./\\\.}"

    # If the override file exists
    if [ -f "$override_file" ]; then
        # Create a temporary file to store the modified content
        temp_file=$(mktemp)

        # Remove the lines containing mount_entry and mount_logs
        grep -vF "$mount_entry" "$override_file" | grep -vF "$mount_logs" > "$temp_file"

        # If the content was changed, replace the original file with the modified one
        if ! diff "$override_file" "$temp_file" > /dev/null; then
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

# 🔁 Restart NGINX Proxy (use when changing docker-compose, mount volume, etc.)
nginx_restart() {
  start_loading "$INFO_DOCKER_NGINX_STARTING"
  pushd "$NGINX_PROXY_DIR" > /dev/null

  run_cmd "docker compose down"
    if [[ $? -ne 0 ]]; then
        print_msg error "$ERROR_DOCKER_NGINX_STOP $NGINX_PROXY_CONTAINER"
        run_cmd "docker ps logs $NGINX_PROXY_CONTAINER"
        popd > /dev/null
        return 1
    fi
  run_cmd "docker compose up -d --force-recreate"
    if [[ $? -ne 0 ]]; then
        print_msg error "$ERROR_DOCKER_NGINX_START $NGINX_PROXY_CONTAINER"
        run_cmd "docker ps logs $NGINX_PROXY_CONTAINER"
        popd > /dev/null
        return 1
    fi
  popd > /dev/null
  stop_loading
  print_msg success "$SUCCESS_DOCKER_NGINX_RESTART"
}


# 🔄 Reload NGINX (use when changing config/nginx.conf/nginx site)
nginx_reload() {
  #echo -e "${YELLOW}🔄 Reloading NGINX Proxy...${NC}"
  start_loading "$INFO_DOCKER_NGINX_RELOADING"
  run_cmd docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload
    if [[ $? -ne 0 ]]; then
        print_msg error "$ERROR_DOCKER_NGINX_RELOAD : $NGINX_PROXY_CONTAINER"
        run_cmd "docker ps logs $NGINX_PROXY_CONTAINER"
        return 1
    fi
    print_msg success "$SUCCESS_DOCKER_NGINX_RELOAD"
}