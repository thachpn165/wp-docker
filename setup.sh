#!/bin/bash

# Màu sắc terminal
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="$PROJECT_ROOT/nginx-proxy"

echo -e "${BLUE}=== WordPress Docker LEMP Stack Setup ===${NC}"

# Kiểm tra và tạo mạng Docker nếu chưa có
if ! docker network ls | grep -q "proxy_network"; then
    echo -e "${YELLOW}🔧 Đang tạo mạng proxy_network...${NC}"
    docker network create proxy_network
else
    echo -e "${GREEN}✅ Mạng proxy_network đã tồn tại.${NC}"
fi

# Kiểm tra trạng thái của NGINX Proxy
NGINX_PROXY_STATUS=$(docker inspect -f '{{.State.Status}}' nginx-proxy 2>/dev/null)

if [[ "$NGINX_PROXY_STATUS" == "running" ]]; then
    echo -e "${GREEN}✅ NGINX Reverse Proxy đang chạy.${NC}"
elif [[ "$NGINX_PROXY_STATUS" == "exited" || "$NGINX_PROXY_STATUS" == "created" ]]; then
    echo -e "${YELLOW}🔄 Đang khởi động lại NGINX Proxy...${NC}"
    docker start nginx-proxy
    echo -e "${GREEN}✅ NGINX Proxy đã khởi động lại.${NC}"
else
    echo -e "${YELLOW}🚀 Khởi động NGINX Reverse Proxy...${NC}"
    cd "$PROXY_DIR"
    docker-compose up -d
    cd "$PROJECT_ROOT"
fi

echo -e "${GREEN}🎉 Hệ thống đã sẵn sàng!${NC}"
