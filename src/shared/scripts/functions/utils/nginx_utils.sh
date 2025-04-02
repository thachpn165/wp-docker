# =====================================
# 🌐 nginx_utils.sh – NGINX Proxy utility functions
# =====================================
update_nginx_override_mounts() {
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
        echo "$MOUNT_ENTRY" | tee -a "$OVERRIDE_FILE" > /dev/null
        echo -e "${GREEN}➕ Added mount source: $MOUNT_ENTRY${NC}"
    else
        echo -e "${YELLOW}${WARNING} Mount source already exists: $MOUNT_ENTRY${NC}"
    fi

    # Kiểm tra và thêm MOUNT_LOGS nếu cần
    if ! grep -Fxq "$MOUNT_LOGS" "$OVERRIDE_FILE"; then
        echo "$MOUNT_LOGS" | tee -a "$OVERRIDE_FILE" > /dev/null
        echo -e "${GREEN}➕ Added mount logs: $MOUNT_LOGS${NC}"
    else
        echo -e "${YELLOW}${WARNING} Mount logs already exists: $MOUNT_LOGS${NC}"
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