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

# Tạo file docker-compose.yml từ template
echo -e "${YELLOW}📄 Đang tạo file docker-compose.yml từ template...${NC}"
TEMPLATE_FILE="$PROJECT_ROOT/shared/templates/docker-compose.yml.template"
TARGET_FILE="$SITES_DIR/$site_name/docker-compose.yml"

if [ -f "$TEMPLATE_FILE" ]; then
    sed -e "s|\${SITE_NAME}|$site_name|g" \
        -e "s|\${PHP_VERSION}|$php_version|g" \
        -e "s|\${MYSQL_PASSWORD}|$(grep 'MYSQL_PASSWORD' "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)|g" \
        "$TEMPLATE_FILE" > "$TARGET_FILE"

    echo -e "${GREEN}✅ File docker-compose.yml đã được tạo tại: $TARGET_FILE${NC}"
else
    echo -e "${RED}❌ Lỗi: Template file không tồn tại: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Khởi động website
echo -e "${GREEN}🚀 Đang khởi động website $domain...${NC}"
cd "$SITES_DIR/$site_name"
docker-compose up -d

# Chờ container PHP khởi động
echo -e "${YELLOW}⏳ Chờ container PHP '$site_name-php' khởi động...${NC}"
sleep 5
if ! docker ps --format "{{.Names}}" | grep -q "$site_name-php"; then
    echo -e "${RED}❌ Lỗi: Container PHP của '$site_name' chưa khởi động. Kiểm tra lại docker-compose.${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Website $domain đã được tạo thành công!${NC}"

# Tạo thư mục SSL
SSL_DIR="$SITES_DIR/$site_name/nginx/ssl"
mkdir -p "$SSL_DIR"

# Tạo chứng chỉ SSL tự ký
echo -e "${YELLOW}🔒 Đang tạo chứng chỉ SSL tự ký cho $domain...${NC}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/$domain.key" \
    -out "$SSL_DIR/$domain.crt" \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"

echo -e "${GREEN}✅ Chứng chỉ SSL tự ký đã được tạo cho $domain${NC}"

# Copy chứng chỉ SSL vào Nginx Proxy
NGINX_PROXY_CONTAINER="nginx-proxy"
SSL_SOURCE_DIR="$SITES_DIR/$site_name/nginx/ssl"
SSL_DEST_DIR="/etc/nginx/ssl"

if [ "$(docker ps -q -f name=$NGINX_PROXY_CONTAINER)" ]; then
    echo -e "${YELLOW}🔄 Copying SSL certificates to Nginx Proxy...${NC}"
    docker cp "$SSL_SOURCE_DIR/$domain.crt" $NGINX_PROXY_CONTAINER:$SSL_DEST_DIR/
    docker cp "$SSL_SOURCE_DIR/$domain.key" $NGINX_PROXY_CONTAINER:$SSL_DEST_DIR/
    echo -e "${GREEN}✅ SSL certificates copied to Nginx Proxy.${NC}"
else
    echo -e "${RED}⚠️ Nginx Proxy is not running, cannot copy SSL certificates.${NC}"
fi


# Tạo file cấu hình NGINX Proxy
echo -e "${YELLOW}📌 Đang tạo file cấu hình NGINX cho website '$domain'...${NC}"

# Tạo file cấu hình NGINX cho Reverse Proxy
cat > "$SITE_CONF_FILE" <<EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $domain;

    ssl_certificate /etc/nginx/ssl/$domain.crt;
    ssl_certificate_key /etc/nginx/ssl/$domain.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Bật HSTS để tăng cường bảo mật HTTPS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_pass http://$site_name-php:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        expires 7d;
        add_header Cache-Control "public, max-age=604800";
        add_header Pragma public;
    }
}
EOF

echo -e "${GREEN}✅ Cấu hình NGINX cho '$domain' đã được tạo tại: $SITE_CONF_FILE${NC}"

# Reload NGINX Proxy để áp dụng cấu hình mới
if [ -f "$PROXY_SCRIPT" ]; then
    bash "$PROXY_SCRIPT"
    echo -e "${GREEN}✅ Đã reload NGINX Proxy. ${NC}"
fi
