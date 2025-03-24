#!/bin/bash

# Import config.sh
CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wp_utils.sh"

# ✅ Thực thi các bước chính
clear
setup_timezone

if ! command -v docker &> /dev/null; then
    install_docker
else
    echo -e "${GREEN}✅ Docker đã được cài đặt.${NC}"
fi

if ! command -v docker compose &> /dev/null; then
    install_docker_compose
else
    echo -e "${GREEN}✅ Docker Compose đã được cài đặt.${NC}"
fi

start_docker_if_needed
check_docker_group

# ✅ Khởi động nginx-proxy và redis nếu chưa chạy
echo -e "${YELLOW}🚀 Kiểm tra và khởi động nginx-proxy và redis-cache nếu cần...${NC}"
cd "$NGINX_PROXY_DIR"

if ! docker compose ps | grep -q "nginx-proxy.*Up"; then
    echo -e "${YELLOW}🌀 Container nginx-proxy chưa chạy. Đang khởi động...${NC}"
    docker compose up -d
else
    echo -e "${GREEN}✅ Container nginx-proxy đang chạy.${NC}"
fi

cd "$PROJECT_ROOT"

# ✅ Kiểm tra và tạo Docker network nếu chưa có
echo -e "${YELLOW}🌐 Kiểm tra mạng Docker '${DOCKER_NETWORK}'...${NC}"
create_docker_network "$DOCKER_NETWORK"


echo -e "\n${GREEN}✅ Hệ thống đã sẵn sàng để sử dụng WP Docker LEMP.${NC}"
