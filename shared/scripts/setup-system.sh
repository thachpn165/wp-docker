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

# Kiểm tra Docker đã cài đặt chưa
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker chưa được cài đặt trên hệ thống.${NC}"
    echo -e "${YELLOW}🔹 Hướng dẫn cài đặt Docker:${NC}"
    
    OS_TYPE=$(uname -s)
    case "$OS_TYPE" in
        Linux*)
            echo -e "${YELLOW}- Ubuntu/Debian: sudo apt-get install -y docker.io${NC}"
            echo -e "${YELLOW}- CentOS: sudo yum install -y docker${NC}"
            echo -e "${YELLOW}- RHEL: sudo dnf install -y docker${NC}"
            echo -e "${YELLOW}- Arch Linux: sudo pacman -S docker${NC}"
            ;;
        Darwin*)
            echo -e "${YELLOW}- macOS: Tải Docker Desktop từ https://www.docker.com/get-started${NC}"
            ;;
        *)
            echo -e "${RED}⚠️ Không xác định được hệ điều hành. Vui lòng tự cài đặt Docker.${NC}"
            ;;
    esac
    exit 1
fi

# Kiểm tra Docker có đang chạy không
is_docker_running
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker không chạy. Hãy khởi động Docker trước!${NC}"
    exit 1
fi

# Tạo mạng Docker nếu chưa có
create_docker_network "$DOCKER_NETWORK"

# Kiểm tra trạng thái của NGINX Proxy
NGINX_STATUS=$(docker inspect -f '{{.State.Status}}' "$NGINX_PROXY_CONTAINER" 2>/dev/null)

if [[ "$NGINX_STATUS" == "running" ]]; then
    echo -e "${GREEN}✅ NGINX Reverse Proxy đang chạy.${NC}"
elif [[ "$NGINX_STATUS" == "exited" || "$NGINX_STATUS" == "created" ]]; then
    echo -e "${YELLOW}🔄 Đang khởi động lại NGINX Proxy...${NC}"
    docker start "$NGINX_PROXY_CONTAINER"
    
    # Kiểm tra lại sau khi khởi động
    sleep 2
    NGINX_STATUS=$(docker inspect -f '{{.State.Status}}' "$NGINX_PROXY_CONTAINER" 2>/dev/null)
    if [[ "$NGINX_STATUS" == "running" ]]; then
        echo -e "${GREEN}✅ NGINX Proxy đã khởi động lại thành công.${NC}"
    else
        echo -e "${RED}❌ Không thể khởi động lại NGINX Proxy. Vui lòng kiểm tra logs.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}🚀 Khởi động NGINX Reverse Proxy...${NC}"
    bash "$NGINX_SCRIPTS_DIR/setup-nginx.sh"

    # Kiểm tra lại sau khi cài đặt
    sleep 3
    NGINX_STATUS=$(docker inspect -f '{{.State.Status}}' "$NGINX_PROXY_CONTAINER" 2>/dev/null)
    if [[ "$NGINX_STATUS" != "running" ]]; then
        echo -e "${RED}❌ Lỗi: NGINX Proxy không khởi động được. Kiểm tra logs để sửa lỗi.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ NGINX Proxy đã khởi động thành công.${NC}"
fi
