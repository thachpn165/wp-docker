# =====================================
# 🌐 nginx_utils.sh – Các hàm tiện ích liên quan đến NGINX Proxy
# =====================================
update_nginx_override_mounts() {
    local site_name="$1"
    local OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
    local MOUNT_ENTRY="      - ../../sites/$site_name/wordpress:/var/www/$site_name"
    local MOUNT_LOGS="      - ../../sites/$site_name/logs:/var/www/logs/$site_name"

    # Nếu chưa tồn tại, tạo file mới
    if [ ! -f "$OVERRIDE_FILE" ]; then
        echo -e "${YELLOW}📄 Tạo mới docker-compose.override.yml...${NC}"
        cat > "$OVERRIDE_FILE" <<EOF
services:
  nginx-proxy:
    volumes:
$MOUNT_ENTRY
$MOUNT_LOGS
EOF
        echo -e "${GREEN}✅ File docker-compose.override.yml đã được tạo và cấu hình.${NC}"
        return
    fi

    # Kiểm tra và thêm MOUNT_ENTRY nếu cần
    if ! grep -Fxq "$MOUNT_ENTRY" "$OVERRIDE_FILE"; then
        echo "$MOUNT_ENTRY" | tee -a "$OVERRIDE_FILE" > /dev/null
        echo -e "${GREEN}➕ Đã thêm mount source: $MOUNT_ENTRY${NC}"
    else
        echo -e "${YELLOW}⚠️ Mount source đã tồn tại: $MOUNT_ENTRY${NC}"
    fi

    # Kiểm tra và thêm MOUNT_LOGS nếu cần
    if ! grep -Fxq "$MOUNT_LOGS" "$OVERRIDE_FILE"; then
        echo "$MOUNT_LOGS" | tee -a "$OVERRIDE_FILE" > /dev/null
        echo -e "${GREEN}➕ Đã thêm mount logs: $MOUNT_LOGS${NC}"
    else
        echo -e "${YELLOW}⚠️ Mount logs đã tồn tại: $MOUNT_LOGS${NC}"
    fi
}


# 🔁 Restart NGINX Proxy (dùng khi thay đổi docker-compose, mount volume, v.v)
nginx_restart() {
  echo -e "${YELLOW}🔁 Đang khởi động lại container NGINX Proxy...${NC}"
  docker restart "$NGINX_PROXY_CONTAINER"
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Đã restart NGINX Proxy thành công.${NC}"
  else
    echo -e "${RED}❌ Lỗi khi restart NGINX Proxy.${NC}"
  fi
}

# 🔄 Reload NGINX (dùng khi thay đổi file config/nginx.conf/nginx site)
nginx_reload() {
  echo -e "${YELLOW}🔄 Đang reload NGINX Proxy...${NC}"
  docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Đã reload NGINX thành công.${NC}"
  else
    echo -e "${RED}⚠️ Lỗi khi reload. Gợi ý: Kiểm tra log bằng 'docker logs $NGINX_PROXY_CONTAINER'${NC}"
  fi
}