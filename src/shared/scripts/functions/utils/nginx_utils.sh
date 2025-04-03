# =====================================
# 🌐 nginx_utils.sh – NGINX Proxy utility functions
# =====================================
nginx_add_mount_docker() {
    local site_name="$1"
    local OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"

    # Nếu đang trong TEST_MODE, sử dụng file mock
    if [[ "$TEST_MODE" == true ]]; then
        OVERRIDE_FILE="/tmp/mock-docker-compose.override.yml"
    fi

    local MOUNT_ENTRY="      - ../../sites/$site_name/wordpress:/var/www/$site_name"
    local MOUNT_LOGS="      - ../../sites/$site_name/logs:/var/www/logs/$site_name"

    # Nếu file không tồn tại, tạo file mới
    if [ ! -f "$OVERRIDE_FILE" ]; then
        echo -e "${YELLOW}📄 Creating new docker-compose.override.yml...${NC}"
        cat > "$OVERRIDE_FILE" <<EOF
services:
  nginx-proxy:
    volumes:
$MOUNT_ENTRY
$MOUNT_LOGS
EOF
        echo -e "${GREEN}${CHECKMARK} docker-compose.override.yml has been created and configured.${NC}"
        return
    fi

    # Kiểm tra và thêm MOUNT_ENTRY nếu cần
    if ! grep -Fxq "$MOUNT_ENTRY" "$OVERRIDE_FILE"; then
        if ! echo "$MOUNT_ENTRY" | tee -a "$OVERRIDE_FILE" > /dev/null; then
            echo -e "${RED}${CROSSMARK} Failed to add mount source: $MOUNT_ENTRY${NC}"
            nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
            return 1
        fi
        echo -e "${GREEN}➕ Added mount source: $MOUNT_ENTRY${NC}"
    else
        echo -e "${YELLOW}${WARNING} Mount source already exists: $MOUNT_ENTRY${NC}"
    fi

    # Kiểm tra và thêm MOUNT_LOGS nếu cần
    if ! grep -Fxq "$MOUNT_LOGS" "$OVERRIDE_FILE"; then
        if ! echo "$MOUNT_LOGS" | tee -a "$OVERRIDE_FILE" > /dev/null; then
            echo -e "${RED}${CROSSMARK} Failed to add mount logs: $MOUNT_LOGS${NC}"
            nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
            return 1
        fi
        echo -e "${GREEN}➕ Added mount logs: $MOUNT_LOGS${NC}"
    else
        echo -e "${YELLOW}${WARNING} Mount logs already exists: $MOUNT_LOGS${NC}"
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
            echo -e "${GREEN}${CHECKMARK} Removed mount entries due to error.${NC}"
        else
            rm -f "$temp_file"
            echo -e "${YELLOW}No changes to mount entries found.${NC}"
        fi
    else
        echo -e "${RED}❌ $override_file does not exist.${NC}"
    fi
}

# 🔁 Restart NGINX Proxy (use when changing docker-compose, mount volume, etc.)
nginx_restart() {
  echo -e "${YELLOW}🔁 Restarting NGINX Proxy container...${NC}"
  pushd "$NGINX_PROXY_DIR" > /dev/null
  docker compose down
  docker compose up -d --force-recreate
  popd > /dev/null
  echo -e "${GREEN}${CHECKMARK} NGINX Proxy has been restarted successfully.${NC}"
}


# 🔄 Reload NGINX (use when changing config/nginx.conf/nginx site)
nginx_reload() {
  echo -e "${YELLOW}🔄 Reloading NGINX Proxy...${NC}"
  docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}${CHECKMARK} NGINX has been reloaded successfully.${NC}"
  else
    echo -e "${RED}${WARNING} Error during reload. Tip: Check logs with 'docker logs $NGINX_PROXY_CONTAINER'${NC}"
  fi
}