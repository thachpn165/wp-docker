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
required_vars=("PROJECT_ROOT" "SITES_DIR" "TEMPLATES_DIR" "CONFIG_DIR" "SCRIPTS_DIR"
               "FUNCTIONS_DIR" "WP_SCRIPTS_DIR" "WEBSITE_MGMT_DIR" "NGINX_PROXY_DIR"
               "NGINX_SCRIPTS_DIR" "SSL_DIR" "DOCKER_NETWORK" "NGINX_PROXY_CONTAINER"
               "SETUP_WORDPRESS_SCRIPT" "PROXY_SCRIPT")

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

# 🚫 Kiểm tra nếu site đã tồn tại
if is_dir_exist "$SITE_DIR"; then
    echo -e "${RED}⚠️ Site '$site_name' đã tồn tại. Hãy chọn tên khác.${NC}"
    exit 1
fi

# 📂 **1. Tạo thư mục cần thiết**
echo -e "${YELLOW}📂 Đang tạo cấu trúc thư mục cho site $domain...${NC}"
mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs}

# 📜 **2. Sao chép cấu hình NGINX Proxy**
NGINX_PROXY_CONF_TEMPLATE="$TEMPLATES_DIR/nginx-proxy.conf.template"
NGINX_PROXY_CONF_TARGET="$NGINX_PROXY_DIR/conf.d/$site_name.conf"

if is_file_exist "$NGINX_PROXY_CONF_TEMPLATE"; then
    cp "$NGINX_PROXY_CONF_TEMPLATE" "$NGINX_PROXY_CONF_TARGET"
    
    if is_file_exist "$NGINX_PROXY_CONF_TARGET"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -e "s|\${SITE_NAME}|$site_name|g" -e "s|\${DOMAIN}|$domain|g" "$NGINX_PROXY_CONF_TARGET"
        else
            sed -i -e "s|\${SITE_NAME}|$site_name|g" -e "s|\${DOMAIN}|$domain|g" "$NGINX_PROXY_CONF_TARGET"
        fi
        echo -e "${GREEN}✅ Cấu hình Nginx Proxy đã được tạo: $NGINX_PROXY_CONF_TARGET${NC}"
    else
        echo -e "${RED}❌ Lỗi: Tệp tin cấu hình Nginx Proxy không tồn tại: $NGINX_PROXY_CONF_TARGET${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy template Nginx Proxy.${NC}"
    exit 1
fi

# ⚙️ **3. Sao chép cấu hình PHP-FPM và MariaDB**
copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini"
copy_file "$TEMPLATES_DIR/php-fpm.conf.template" "$SITE_DIR/php/php-fpm.conf"
copy_file "$TEMPLATES_DIR/mariadb-custom.cnf.template" "$SITE_DIR/mariadb/conf.d/custom.cnf"

# 📄 **4. Tạo file .env**
echo -e "${YELLOW}📄 Đang tạo file .env...${NC}"
mkdir -p "$SITE_DIR"

MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
MYSQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

cat > "$SITE_DIR/.env" <<EOF
SITE_NAME=$site_name
DOMAIN=$domain
PHP_VERSION=$php_version
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
if is_container_running "$NGINX_PROXY_CONTAINER"; then
    echo -e "${YELLOW}🔄 Reloading Nginx Proxy...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload
    echo -e "${GREEN}✅ Nginx Proxy đã được reload.${NC}"
else
    echo -e "${RED}⚠️ Nginx Proxy không chạy. Vui lòng kiểm tra lại!${NC}"
fi

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
