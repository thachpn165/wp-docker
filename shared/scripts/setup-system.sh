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

# Kiểm tra Docker có đang chạy không
is_docker_running
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker không chạy. Hãy khởi động Docker trước!${NC}"
    exit 1
fi

# Tạo mạng Docker nếu chưa có
create_docker_network "$DOCKER_NETWORK"

# Kiểm tra và khởi động NGINX Proxy
setup_nginx_proxy
