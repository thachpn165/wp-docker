#!/bin/bash

# Màu sắc terminal
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔄 Đang reload NGINX Proxy...${NC}"
docker exec nginx-proxy nginx -s reload

if [ $? -eq 0 ]; then
    echo -e "${GREEN}${CHECKMARK} NGINX Proxy đã được reload thành công!${NC}"
else
    echo -e "${RED}${CROSSMARK} Lỗi khi reload NGINX Proxy.${NC}"
    exit 1
fi
