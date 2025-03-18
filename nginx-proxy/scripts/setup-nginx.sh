#!/bin/bash

# Màu sắc terminal
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Kiểm tra mạng proxy_network...${NC}"
docker network ls | grep proxy_network > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${GREEN}🔧 Tạo mạng proxy_network...${NC}"
    docker network create proxy_network
else
    echo -e "${GREEN}✅ Mạng proxy_network đã tồn tại.${NC}"
fi

echo -e "${YELLOW}🚀 Khởi động NGINX Proxy...${NC}"
docker-compose -f nginx-proxy/docker-compose.yml up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ NGINX Proxy đã được khởi động thành công!${NC}"
else
    echo -e "${RED}❌ Lỗi khi khởi động NGINX Proxy.${NC}"
    exit 1
fi
