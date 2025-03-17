#!/bin/bash

# Màu sắc terminal
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Kiểm tra tham số
if [ -z "$1" ]; then
    echo -e "${RED}❌ Lỗi: Chưa nhập tên website.${NC}"
    exit 1
fi

# Biến hệ thống
site_name="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SITES_DIR="$PROJECT_ROOT/sites"
WP_DIR="$SITES_DIR/$site_name/wordpress"
CONTAINER_PHP="${site_name}-php"

echo -e "${BLUE}🔹 Bắt đầu cài đặt WordPress cho '$site_name'...${NC}"

# Kiểm tra xem container PHP đã khởi động chưa
echo -e "${YELLOW}⏳ Chờ container PHP '$CONTAINER_PHP' khởi động...${NC}"
sleep 10

if ! docker ps --format '{{.Names}}' | grep -q "$CONTAINER_PHP"; then
    echo -e "${RED}❌ Lỗi: Container PHP '$CONTAINER_PHP' chưa chạy. Hãy kiểm tra lại!${NC}"
    exit 1
fi

# Lấy thông tin database từ .env
DB_NAME=$(grep "MYSQL_DATABASE=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)
DB_USER=$(grep "MYSQL_USER=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)
DB_PASS=$(grep "MYSQL_PASSWORD=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)

# **Tạo wp-config.php từ wp-config-sample.php bên trong container PHP**
echo -e "${YELLOW}⚙️ Đang cấu hình wp-config.php bên trong container PHP...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php && \
    sed -i 's/database_name_here/$DB_NAME/' /var/www/html/wp-config.php && \
    sed -i 's/username_here/$DB_USER/' /var/www/html/wp-config.php && \
    sed -i 's/password_here/$DB_PASS/' /var/www/html/wp-config.php && \
    sed -i 's/localhost/mariadb/' /var/www/html/wp-config.php
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ wp-config.php đã được cấu hình bên trong container.${NC}"
else
    echo -e "${RED}❌ Lỗi khi cấu hình wp-config.php.${NC}"
    exit 1
fi

# Cài đặt WP-CLI trong container nếu chưa có
echo -e "${YELLOW}🔄 Kiểm tra và cài đặt WP-CLI...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    if ! command -v wp > /dev/null; then
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
        chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
    fi
"

# Cài đặt WordPress với WP-CLI
echo -e "${YELLOW}🚀 Đang cài đặt WordPress với WP-CLI...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    wp core install --url='https://$site_name.dev' --title='$site_name' --admin_user='admin' --admin_password='admin123' --admin_email='admin@$site_name.dev' --skip-email --allow-root --path=/var/www/html
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ WordPress đã được cài đặt thành công.${NC}"
else
    echo -e "${RED}❌ Lỗi khi cài đặt WordPress.${NC}"
    exit 1
fi

# Xóa plugin mặc định
echo -e "${YELLOW}🧹 Đang dọn dẹp plugin mặc định...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "wp plugin delete hello akismet --allow-root --path=/var/www/html"
echo -e "${GREEN}✅ Plugin mặc định đã được xóa.${NC}"

# Cấu hình permalink
echo -e "${YELLOW}🔄 Cấu hình Permalink...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "wp option update permalink_structure '/%postname%/' --allow-root --path=/var/www/html"
echo -e "${GREEN}✅ Permalink đã được thiết lập.${NC}"

# Cấu hình bảo mật
echo -e "${YELLOW}🔐 Đang cấu hình bảo mật cho WordPress...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    wp option update blog_public 0 --allow-root --path=/var/www/html && \
    wp option update timezone_string 'Asia/Ho_Chi_Minh' --allow-root --path=/var/www/html
"
echo -e "${GREEN}✅ WordPress đã được cài đặt thành công với bảo mật tối ưu.${NC}"
