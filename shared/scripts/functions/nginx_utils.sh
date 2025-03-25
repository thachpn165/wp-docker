update_nginx_override_mounts() {
    local site_name="$1"
    local OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
    local MOUNT_ENTRY="      - ../sites/$site_name/wordpress:/var/www/$site_name"
    local MOUNT_LOGS="      - ../sites/$site_name/logs:/var/www/logs/$site_name"

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


# Restart NGINX Proxy
restart_nginx_proxy() {
    echo -e "${YELLOW}🔄 Đang khởi động lại NGINX Proxy với docker-compose.override.yml...${NC}"

    # Di chuyển vào thư mục chứa docker-compose.yml
    cd "$NGINX_PROXY_DIR" || {
        echo -e "${RED}❌ Lỗi: Không thể truy cập thư mục $NGINX_PROXY_DIR${NC}"
        return 1
    }

    # Dừng tất cả container trong docker-compose.yml và override
    echo -e "${BLUE}🛑 Đang dừng tất cả container...${NC}"
    docker compose down

    # Chờ 2 giây để đảm bảo container dừng hoàn toàn (tránh lỗi mount)
    sleep 2

    # Khởi động lại Docker Compose mà không chỉ định -f, để nó tự động load override
    echo -e "${GREEN}🚀 Đang khởi động lại container NGINX Proxy...${NC}"
    docker compose up -d

    # Kiểm tra xem container có khởi động thành công không
    if docker ps --format '{{.Names}}' | grep -q "^$NGINX_PROXY_CONTAINER$"; then
        echo -e "${GREEN}✅ NGINX Proxy đã được khởi động lại thành công.${NC}"
    else
        echo -e "${RED}❌ Lỗi: Không thể khởi động lại NGINX Proxy.${NC}"
    fi

    # Quay về thư mục cũ (nếu cần)
    cd - > /dev/null 2>&1
}