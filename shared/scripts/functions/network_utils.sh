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
    if command -v timeout &>/dev/null; then
    timeout 3 nslookup "$domain" &> /dev/null
    else
    nslookup "$domain" | grep -q "Name:"
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

