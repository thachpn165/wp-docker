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

# Kiểm tra quyền sudo nếu cần
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}⚠️ Script này cần chạy với quyền sudo!${NC}"
    echo -e "${YELLOW}💡 Hãy thử chạy: ${GREEN}sudo bash setup.sh${NC}"
    exit 1
fi

echo -e "${BLUE}=== WordPress Docker LEMP Stack Setup ===${NC}"

# 1️⃣ **Kiểm tra Docker có chạy không**
is_docker_running
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker không chạy. Hãy khởi động Docker trước!${NC}"
    exit 1
fi

# 2️⃣ **Tạo mạng Docker nếu chưa tồn tại**
create_docker_network "$DOCKER_NETWORK"

# 3️⃣ **Kiểm tra trạng thái của NGINX Proxy**
setup_nginx_proxy

echo -e "${GREEN}🎉 Hệ thống đã sẵn sàng!${NC}"
