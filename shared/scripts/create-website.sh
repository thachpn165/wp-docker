#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Xác định đường dẫn tuyệt đối của `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# 🛠 Kiểm tra biến quan trọng
required_vars=("PROJECT_ROOT" "SITES_DIR" "TEMPLATES_DIR" "NGINX_PROXY_DIR"
               "SSL_DIR" "DOCKER_NETWORK" "NGINX_PROXY_CONTAINER")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
        exit 1
    fi
done

echo -e "${BLUE}===== TẠO WEBSITE WORDPRESS MỚI =====${NC}"

# 📌 Nhập thông tin cần thiết
read -p "Tên miền (ví dụ: example.com): " domain
read -p "Tên site (viết thường, không dấu, dùng dấu - nếu cần): " site_name
read -p "Chọn phiên bản PHP (7.4, 8.1, 8.3) [mặc định: 8.3]: " php_version
php_version=${php_version:-8.3}

SITE_DIR="$SITES_DIR/$site_name"
NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$site_name.conf"

# 🚫 Kiểm tra nếu site đã tồn tại
if is_dir_exist "$SITE_DIR"; then
    echo -e "${RED}⚠️ Site '$site_name' đã tồn tại. Hãy chọn tên khác.${NC}"
    exit 1
fi

# 📂 **1. Tạo thư mục cần thiết**
echo -e "${YELLOW}📂 Đang tạo cấu trúc thư mục cho site $domain...${NC}"
mkdir -p "$SITE_DIR/mariadb/conf.d" "$SITE_DIR/wordpress" "$SITE_DIR/logs"

# 📜 **2. Tạo cấu hình NGINX mặc định**
NGINX_TEMPLATE="$TEMPLATES_DIR/nginx-default.conf.template"

if is_file_exist "$NGINX_TEMPLATE"; then
    cp "$NGINX_TEMPLATE" "$NGINX_CONF_FILE"
    
    # Thay thế biến trong tập tin cấu hình
    sed -i -e "s|\${SITE_NAME}|$site_name|g" \
           -e "s|\${DOMAIN}|$domain|g" "$NGINX_CONF_FILE"

    echo -e "${GREEN}✅ Cấu hình NGINX mặc định đã được tạo: $NGINX_CONF_FILE${NC}"
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy template nginx-default.conf.template.${NC}"
    exit 1
fi

# 🌀 **Restart lại NGINX Proxy để nhận diện cấu hình cache**
restart_nginx_proxy

# ⚙️ **3. Tạo cấu hình tối ưu PHP-FPM**
echo -e "${YELLOW}⚙️ Đang tạo cấu hình PHP-FPM tối ưu...${NC}"
create_optimized_php_fpm_config "$SITE_DIR/php/php-fpm.conf"
echo -e "${GREEN}✅ Cấu hình PHP-FPM tối ưu đã được tạo.${NC}"

# 📄 **4. Tạo file .env**
echo -e "${YELLOW}📄 Đang tạo file .env...${NC}"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
MYSQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

cat > "$SITE_DIR/.env" <<EOF
SITE_NAME=$site_name
DOMAIN=$domain
PHP_VERSION=$php_version
CACHE_TYPE=no-cache
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF

# 📦 **5. Tạo file docker-compose.yml từ template**
echo -e "${YELLOW}📄 Đang tạo file docker-compose.yml từ template...${NC}"
TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
TARGET_FILE="$SITE_DIR/docker-compose.yml"

if is_file_exist "$TEMPLATE_FILE"; then
    set -o allexport
    source "$SITE_DIR/.env"
    set +o allexport
    envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE"
    echo -e "${GREEN}✅ File docker-compose.yml đã được tạo.${NC}"
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy template docker-compose.yml.${NC}"
    exit 1
fi

# 🚀 **6. Khởi động website**
echo -e "${GREEN}🚀 Đang khởi động website $domain...${NC}"
cd "$SITE_DIR"
docker-compose up -d

echo -e "${GREEN}🎉 Website $domain đã được tạo thành công!${NC}"

# 🔐 **7. Tạo chứng chỉ SSL tự ký**
SSL_PATH="$SSL_DIR/$domain"
generate_ssl_cert "$domain" "$SSL_DIR"

# 🔄 **8. Kiểm tra và reload NGINX Proxy**
restart_nginx_proxy

# 📌 **9. Cài đặt WordPress**
if is_file_exist "$SETUP_WORDPRESS_SCRIPT"; then
    echo -e "${YELLOW}🚀 Đang chạy script cài đặt WordPress...${NC}"
    bash "$SETUP_WORDPRESS_SCRIPT" "$site_name"
    echo -e "${GREEN}✅ Cài đặt WordPress hoàn tất.${NC}"
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy script cài đặt WordPress.${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Hoàn tất quá trình tạo website $domain.${NC}"
