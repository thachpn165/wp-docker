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

# Kiểm tra UID hiện tại của user thực thi script
HOST_UID=$(id -u)

# 🛠 Kiểm tra biến quan trọng
# ✅ Biến bắt buộc
required_vars=(
  "PROJECT_ROOT" "SITES_DIR" "TEMPLATES_DIR" "CONFIG_DIR" "SCRIPTS_DIR"
  "FUNCTIONS_DIR" "WP_SCRIPTS_DIR" "WEBSITE_MGMT_DIR" "NGINX_PROXY_DIR"
  "NGINX_SCRIPTS_DIR" "SSL_DIR" "DOCKER_NETWORK" "NGINX_PROXY_CONTAINER"
  "SETUP_WORDPRESS_SCRIPT" "PROXY_SCRIPT"
)

check_required_envs "${required_vars[@]}"

echo -e "${BLUE}===== TẠO WEBSITE WORDPRESS MỚI =====${NC}"

# 📌 Nhập thông tin cần thiết
read -p "Tên miền (ví dụ: example.com): " domain

# Tạo gợi ý tên site từ tên miền (bỏ phần đuôi)
suggested_site_name=$(echo "$domain" | sed -E 's/\.[a-zA-Z]+$//')
read -p "Tên site (dùng để quản lý, không ký tự đặc biệt, có thể dùng dấu gạch ngang (-). Mặc định: $suggested_site_name): " site_name

site_name=${site_name:-$suggested_site_name}
read -p "Chọn phiên bản PHP (7.4, 8.1, 8.3) [mặc định: 8.3]: " php_version
php_version=${php_version:-8.3}

SITE_DIR="$SITES_DIR/$site_name"
CONTAINER_PHP="${site_name}-php"

# 🚫 Kiểm tra nếu site đã tồn tại
if is_directory_exist "$SITE_DIR" false; then
    echo "❌ Website '$site_name' đã tồn tại. Vui lòng chọn tên khác."
    exit 1
else
    echo "✅ Bắt đầu tạo website mới: $site_name"
fi

# 📂 **1. Tạo thư mục cần thiết**
echo -e "${YELLOW}📂 Đang tạo cấu trúc thư mục cho site $domain...${NC}"
mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
touch "$SITE_DIR/logs/access.log" "$SITE_DIR/logs/error.log"
chmod 666 "$SITE_DIR/logs/"*.log
echo -e "${YELLOW}📄 Đang tạo file .env...${NC}"
mkdir -p "$SITE_DIR"

# 🛠 **2. Cập nhật `docker-compose.override.yml`**
OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
MOUNT_ENTRY="      - ../sites/$site_name/wordpress:/var/www/$site_name"
MOUNT_LOGS="      - ../sites/$site_name/logs:/var/www/logs/$site_name"

# Nếu file chưa tồn tại, tạo mới
if [ ! -f "$OVERRIDE_FILE" ]; then
    echo -e "${YELLOW}📄 Tạo mới docker-compose.override.yml...${NC}"
    cat > "$OVERRIDE_FILE" <<EOF
version: '3.8'
services:
  nginx-proxy:
    volumes:
$MOUNT_ENTRY
$MOUNT_LOGS
EOF
    echo -e "${GREEN}✅ Tạo mới và cập nhật docker-compose.override.yml thành công.${NC}"
else
    # Kiểm tra nếu website đã được mount chưa
    if ! grep -q "$MOUNT_ENTRY" "$OVERRIDE_FILE"; then
        echo "$MOUNT_ENTRY" >> "$OVERRIDE_FILE"
        echo -e "${GREEN}✅ Website '$site_name' đã được thêm vào docker-compose.override.yml.${NC}"
    else
        echo -e "${YELLOW}⚠️ Website '$site_name' đã tồn tại trong docker-compose.override.yml.${NC}"
    fi
    
    # Kiểm tra nếu logs đã được mount chưa
    if ! grep -q "$MOUNT_LOGS" "$OVERRIDE_FILE"; then
        echo "$MOUNT_LOGS" >> "$OVERRIDE_FILE"
        echo -e "${GREEN}✅ Logs của website '$site_name' đã được thêm vào docker-compose.override.yml.${NC}"
    else
        echo -e "${YELLOW}⚠️ Logs của website '$site_name' đã tồn tại trong docker-compose.override.yml.${NC}"
    fi
fi

# 📜 **2. Sao chép cấu hình NGINX Proxy**
NGINX_PROXY_CONF_TEMPLATE="$TEMPLATES_DIR/nginx-proxy.conf.template"
NGINX_PROXY_CONF_TARGET="$NGINX_PROXY_DIR/conf.d/$site_name.conf"

# Xóa tập tin cấu hình cũ nếu tồn tại
if is_file_exist "$NGINX_PROXY_CONF_TARGET"; then
    echo -e "${YELLOW}🗑️ Đang xóa cấu hình cũ của NGINX Proxy: $NGINX_PROXY_CONF_TARGET${NC}"
    rm -f "$NGINX_PROXY_CONF_TARGET"
fi

# Sao chép lại cấu hình từ template
if is_file_exist "$NGINX_PROXY_CONF_TEMPLATE"; then
    cp "$NGINX_PROXY_CONF_TEMPLATE" "$NGINX_PROXY_CONF_TARGET"

    if is_file_exist "$NGINX_PROXY_CONF_TARGET"; then
        # Kiểm tra hệ điều hành để sử dụng `sed` đúng cách
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -e "s|\${SITE_NAME}|$site_name|g" \
                      -e "s|\${DOMAIN}|$domain|g" \
                      -e "s|\${PHP_CONTAINER}|$site_name-php|g" \
                      "$NGINX_PROXY_CONF_TARGET"
        else
            sed -i -e "s|\${SITE_NAME}|$site_name|g" \
                   -e "s|\${DOMAIN}|$domain|g" \
                   -e "s|\${PHP_CONTAINER}|$site_name-php|g" \
                   "$NGINX_PROXY_CONF_TARGET"
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



# ⚙️ **3. Sao chép cấu hình php.ini mặc định**
copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini"

# ⚙️ **3. Tạo cấu hình tối ưu MariaDB**
echo -e "${YELLOW}⚙️ Đang tạo cấu hình MariaDB tối ưu...${NC}"
apply_mariadb_config "$SITE_DIR/mariadb/conf.d/custom.cnf"
echo -e "${GREEN}✅ Cấu hình MariaDB tối ưu đã được tạo.${NC}"

# ⚙️ **4. Tạo cấu hình PHP-FPM tối ưu**
echo -e "${YELLOW}⚙️ Đang tạo cấu hình PHP-FPM tối ưu...${NC}"
create_optimized_php_fpm_config "$SITE_DIR/php/php-fpm.conf"
echo -e "${GREEN}✅ Cấu hình PHP-FPM tối ưu đã được tạo.${NC}"

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
docker compose up -d

echo -e "${GREEN}🎉 Website $domain đã được tạo thành công!${NC}"

# 🔐 **7. Tạo chứng chỉ SSL tự ký**
SSL_PATH="$SSL_DIR/$domain"
generate_ssl_cert "$domain" "$SSL_DIR"

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

restart_nginx_proxy

# Chạy lệnh chown bên trong container nginx-proxy
echo -e "${GREEN}🔄 Thiết lập quyền bên trong container${NC}"
docker exec -u root "$NGINX_PROXY_CONTAINER" chown -R nobody:nogroup "/var/www/$site_name"
docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup "/var/www/"

# 📋 Hiển thị thông tin WordPress sau cùng (từ .wp-info)
WP_INFO_FILE="$SITE_DIR/.wp-info"

if [ -f "$WP_INFO_FILE" ]; then
    echo -e "${GREEN}"
    echo -e "==================================================="
    echo -e "🎉 WordPress đã được cài đặt thành công! 🎉"
    echo -e "==================================================="
    cat "$WP_INFO_FILE" | while read line; do
        echo -e "${YELLOW}$line${GREEN}"
    done
    echo -e "==================================================="
    echo -e "🚀 Hãy truy cập website của bạn ngay bây giờ!"
    echo -e "==================================================="
    echo -e "${NC}"
    rm -f "$WP_INFO_FILE"
fi
