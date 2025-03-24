update_nginx_override_mounts() {
    local site_name="$1"
    local OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
    local MOUNT_ENTRY="      - ../sites/$site_name/wordpress:/var/www/$site_name"
    local MOUNT_LOGS="      - ../sites/$site_name/logs:/var/www/logs/$site_name"

    if [ ! -f "$OVERRIDE_FILE" ]; then
        echo -e "${YELLOW}📄 Tạo mới docker-compose.override.yml...${NC}"
        cat > "$OVERRIDE_FILE" <<EOF
version: '3.8'
services:
  nginx-proxy:
    volumes:
$MOUNT_ENTRY
$MOUNT_LOGS
EOF
        echo -e "${GREEN}✅ Tạo mới và cập nhật docker-compose.override.yml thành công.${NC}"
    else
        if ! grep -q "$MOUNT_ENTRY" "$OVERRIDE_FILE"; then
            echo "$MOUNT_ENTRY" >> "$OVERRIDE_FILE"
            echo -e "${GREEN}✅ Website '$site_name' đã được thêm vào docker-compose.override.yml.${NC}"
        else
            echo -e "${YELLOW}⚠️ Website '$site_name' đã tồn tại trong docker-compose.override.yml.${NC}"
        fi
        if ! grep -q "$MOUNT_LOGS" "$OVERRIDE_FILE"; then
            echo "$MOUNT_LOGS" >> "$OVERRIDE_FILE"
            echo -e "${GREEN}✅ Logs của website '$site_name' đã được thêm vào docker-compose.override.yml.${NC}"
        else
            echo -e "${YELLOW}⚠️ Logs của website '$site_name' đã tồn tại trong docker-compose.override.yml.${NC}"
        fi
    fi
}
