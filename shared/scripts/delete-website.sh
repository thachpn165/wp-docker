#!/bin/bash

# Màu sắc terminal
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Xác định thư mục chứa website
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SITES_DIR="$PROJECT_ROOT/sites"
PROXY_SCRIPT="$PROJECT_ROOT/nginx-proxy/restart-nginx-proxy.sh"
PROXY_CONF_DIR="$PROJECT_ROOT/nginx-proxy/conf.d"

echo -e "${YELLOW}📋 Danh sách các website có thể xóa:${NC}"
ls "$SITES_DIR"
echo ""

read -p "Nhập tên website cần xóa: " site_name

# Kiểm tra xem website có tồn tại không
if [ ! -d "$SITES_DIR/$site_name" ]; then
    echo -e "${RED}❌ Website '$site_name' không tồn tại!${NC}"
    exit 1
fi

# Lấy thông tin domain từ .env của website
ENV_FILE="$SITES_DIR/$site_name/.env"
if [ -f "$ENV_FILE" ]; then
    domain=$(grep "DOMAIN=" "$ENV_FILE" | cut -d'=' -f2)
else
    echo -e "${RED}❌ Không tìm thấy file .env của website!${NC}"
    exit 1
fi

SITE_CONF_FILE="$PROXY_CONF_DIR/$site_name.conf"
SSL_DIR="$SITES_DIR/$site_name/nginx/ssl"

# Xác nhận xóa
echo -e "${RED}⚠️ Bạn có chắc muốn xóa website '$site_name' ($domain)? (y/n): ${NC}"
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️ Hủy thao tác xóa website '${site_name}'.${NC}"
    exit 0
fi

echo -e "${BLUE}🔄 Đang xóa website '$site_name'...${NC}"

# Dừng & xóa container
cd "$SITES_DIR/$site_name"
docker-compose down
cd "$PROJECT_ROOT"

# Xóa thư mục website
rm -rf "$SITES_DIR/$site_name"
echo -e "${GREEN}✅ Website '$site_name' đã bị xóa thành công!${NC}"

# Xóa file cấu hình NGINX của website
if [ -f "$SITE_CONF_FILE" ]; then
    echo -e "${YELLOW}🗑️ Đang xóa cấu hình NGINX của '$domain'...${NC}"
    rm -f "$SITE_CONF_FILE"
    echo -e "${GREEN}✅ Cấu hình NGINX của '$domain' đã được xóa.${NC}"
else
    echo -e "${RED}⚠️ Không tìm thấy file cấu hình $SITE_CONF_FILE. Bỏ qua.${NC}"
fi

# Xóa chứng chỉ SSL nếu tồn tại
if [ -d "$SSL_DIR" ]; then
    echo -e "${YELLOW}🗑️ Đang xóa chứng chỉ SSL của '$site_name'...${NC}"
    rm -rf "$SSL_DIR"
    echo -e "${GREEN}✅ Chứng chỉ SSL của '$site_name' đã bị xóa.${NC}"
else
    echo -e "${RED}⚠️ Không tìm thấy chứng chỉ SSL của '$site_name'. Bỏ qua.${NC}"
fi

# Xóa mạng site_network nếu không còn container nào đang sử dụng
if docker network inspect site_network >/dev/null 2>&1; then
    echo -e "${YELLOW}🗑️ Đang kiểm tra và xóa mạng site_network của '$site_name' nếu không cần thiết...${NC}"
    docker network rm site_network
fi

# Reload NGINX Proxy để cập nhật lại cấu hình
if [ -f "$PROXY_SCRIPT" ]; then
    bash "$PROXY_SCRIPT"
else
    echo -e "${RED}⚠️ Không tìm thấy tập tin $PROXY_SCRIPT. Hãy kiểm tra lại.${NC}"
fi

echo -e "${GREEN}✅ Hoàn tất xóa website '$site_name'.${NC}"

read -p "Nhấn Enter để quay lại menu..."
