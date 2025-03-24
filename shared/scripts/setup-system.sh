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

echo -e "\n${GREEN}✅ Hệ thống đã sẵn sàng để sử dụng WP Docker LEMP.${NC}"
