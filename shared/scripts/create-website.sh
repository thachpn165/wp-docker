#!/bin/bash

# Màu sắc terminal
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Nhập thông tin cần thiết
read -p "Tên miền (ví dụ: example.com): " domain
read -p "Tên site (viết thường, không dấu, dùng dấu - nếu cần): " site_name
read -p "Chọn phiên bản PHP (7.4, 8.1, 8.3) [mặc định: 8.3]: " php_version
php_version=${php_version:-8.3}

# Thiết lập biến
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SITES_DIR="$PROJECT_ROOT/sites"
TEMPLATES_DIR="$PROJECT_ROOT/shared/templates"
PROXY_SCRIPT="$PROJECT_ROOT/nginx-proxy/restart-nginx-proxy.sh"
PROXY_CONF_DIR="$PROJECT_ROOT/nginx-proxy/conf.d"
SITE_CONF_FILE="$PROXY_CONF_DIR/$site_name.conf"

echo -e "${BLUE}===== TẠO WEBSITE WORDPRESS MỚI =====${NC}"

# Kiểm tra site đã tồn tại chưa
if [ -d "$SITES_DIR/$site_name" ]; then
    echo -e "${RED}⚠️ Site '$site_name' đã tồn tại. Hãy chọn tên khác.${NC}"
    exit 1
fi

# Tạo thư mục website
echo -e "${YELLOW}📂 Đang tạo cấu trúc thư mục cho site $domain...${NC}"
mkdir -p "$SITES_DIR/$site_name"/{nginx/{conf.d,ssl},php/{tmp},mariadb,wordpress,logs}

# Tạo file .env
echo -e "${YELLOW}📄 Đang tạo file .env...${NC}"
cat > "$SITES_DIR/$site_name/.env" <<EOF
SITE_NAME=$site_name
DOMAIN=$domain
PHP_VERSION=$php_version
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=$(openssl rand -base64 12)
EOF

# Tạo file docker-compose.yml
echo -e "${YELLOW}📄 Đang tạo file docker-compose.yml...${NC}"
cat > "$SITES_DIR/$site_name/docker-compose.yml" <<EOF
version: '3.8'
services:
  php:
    image: php:$php_version-fpm
    volumes:
      - ./wordpress:/var/www/html
  mariadb:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: $(grep "MYSQL_PASSWORD" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)
  nginx:
    image: nginx:stable-alpine
    ports:
      - "80"
      - "443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
      - ./wordpress:/var/www/html
EOF

# Khởi động website
echo -e "${GREEN}🚀 Đang khởi động website $domain...${NC}"
cd "$SITES_DIR/$site_name"
docker-compose up -d

echo -e "${GREEN}🎉 Website $domain đã được tạo thành công!${NC}"

# Tạo file cấu hình NGINX Proxy
echo -e "${YELLOW}📌 Đang tạo file cấu hình NGINX cho website '$domain'...${NC}"

# Tạo file cấu hình NGINX cho Reverse Proxy
cat > "$SITE_CONF_FILE" <<EOF
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://$site_name-php:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo -e "${GREEN}✅ Cấu hình NGINX cho '$domain' đã được tạo tại: $SITE_CONF_FILE${NC}"

# Reload NGINX Proxy để áp dụng cấu hình mới
if [ -f "$PROXY_SCRIPT" ]; then
    bash "$PROXY_SCRIPT"
else
    echo -e "${RED}⚠️ Không tìm thấy tập tin $PROXY_SCRIPT. Hãy kiểm tra lại.${NC}"
fi