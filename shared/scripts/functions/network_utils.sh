#!/bin/bash

# Kiểm tra xem một port có đang được sử dụng không
is_port_in_use() {
    local port="$1"
    netstat -tuln | grep -q ":$port "
}

# Kiểm tra kết nối Internet
is_internet_connected() {
    ping -c 1 8.8.8.8 &> /dev/null
}

# Kiểm tra xem một domain có thể truy cập không
is_domain_resolvable() {
    local domain="$1"
    nslookup "$domain" &> /dev/null
}
# Thiết lập proxy NGINX
setup_nginx_proxy() {
    local nginx_status=$(docker inspect -f '{{.State.Status}}' "$NGINX_PROXY_CONTAINER" 2>/dev/null)

    if [[ "$nginx_status" == "running" ]]; then
        echo -e "${GREEN}✅ NGINX Reverse Proxy đang chạy.${NC}"
    elif [[ "$nginx_status" == "exited" || "$nginx_status" == "created" ]]; then
        echo -e "${YELLOW}🔄 Đang khởi động lại NGINX Proxy...${NC}"
        docker start "$NGINX_PROXY_CONTAINER"
        echo -e "${GREEN}✅ NGINX Proxy đã khởi động lại.${NC}"
    else
        echo -e "${YELLOW}🚀 Khởi động NGINX Reverse Proxy...${NC}"
        bash "$NGINX_SCRIPTS_DIR/setup-nginx.sh"
    fi
}

# Restart NGINX Proxy
restart_nginx_proxy() {
    echo "🔄 Đang reload NGINX Proxy..."
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload || echo "⚠️ Không thể reload NGINX Proxy!"
}

# Hàm kiểm tra một mạng Docker có tồn tại không
is_network_exists() {
    local network_name="$1"
    if docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"; then
        return 0  # Network tồn tại
    else
        return 1  # Network không tồn tại
    fi
}

# Thiết lập network Docker
create_docker_network() {
    local network_name="$1"
    if ! docker network ls | grep -q "$network_name"; then
        echo -e "${YELLOW}🔧 Đang tạo mạng $network_name...${NC}"
        docker network create "$network_name"
        echo -e "${GREEN}✅ Mạng $network_name đã được tạo.${NC}"
    else
        echo -e "${GREEN}✅ Mạng $network_name đã tồn tại.${NC}"
    fi
}

