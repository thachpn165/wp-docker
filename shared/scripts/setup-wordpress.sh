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

# Kiểm tra thư mục WordPress
if [ ! -d "$WP_DIR" ]; then
    echo -e "${YELLOW}📂 Tạo thư mục WordPress...${NC}"
    mkdir -p "$WP_DIR"
fi

# Tải WordPress nếu chưa có
if [ ! -f "$WP_DIR/index.php" ]; then
    echo -e "${YELLOW}📥 Đang tải WordPress...${NC}"
    curl -L https://wordpress.org/latest.tar.gz | tar xz --strip-components=1 -C "$WP_DIR"
    echo -e "${GREEN}✅ WordPress đã được tải xuống.${NC}"
fi

# Lấy thông tin database từ .env
DB_NAME=$(grep "MYSQL_DATABASE=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)
DB_USER=$(grep "MYSQL_USER=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)
DB_PASS=$(grep "MYSQL_PASSWORD=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2)

# Tạo wp-config.php từ wp-config-sample.php
if [ -f "$WP_DIR/wp-config-sample.php" ]; then
    echo -e "${YELLOW}⚙️ Đang cấu hình wp-config.php từ wp-config-sample.php...${NC}"
    cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"

    sed -i ' ' "s/database_name_here/$DB_NAME/" "$WP_DIR/wp-config.php"
    sed -i ' ' "s/username_here/$DB_USER/" "$WP_DIR/wp-config.php"
    sed -i ' ' "s/password_here/$DB_PASS/" "$WP_DIR/wp-config.php"
    sed -i ' ' "s/localhost/mariadb/" "$WP_DIR/wp-config.php"

    echo -e "${GREEN}✅ wp-config.php đã được cấu hình.${NC}"
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy wp-config-sample.php.${NC}"
    exit 1
fi

# Kiểm tra xem container PHP đã khởi động chưa
echo -e "${YELLOW}⏳ Chờ container PHP '$CONTAINER_PHP' khởi động...${NC}"
sleep 10  # Chờ 10s để đảm bảo container PHP sẵn sàng

if ! docker ps --format '{{.Names}}' | grep -q "$CONTAINER_PHP"; then
    echo -e "${RED}❌ Lỗi: Container PHP '$CONTAINER_PHP' chưa chạy. Hãy kiểm tra lại!${NC}"
    exit 1
fi

# Cài đặt WP-CLI trong container nếu chưa có
echo -e "${YELLOW}🔄 Kiểm tra và cài đặt WP-CLI...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "if ! command -v wp > /dev/null; then curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp; fi"

# Kiểm tra lại WP-CLI
docker exec -i "$CONTAINER_PHP" sh -c "wp --info --allow-root"

# Cài đặt WordPress với WP-CLI
echo -e "${YELLOW}🚀 Đang cài đặt WordPress với WP-CLI...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "wp core install --url='https://$site_name.dev' --title='$site_name' --admin_user='admin' --admin_password='admin123' --admin_email='admin@$site_name.dev' --skip-email --path=/var/www/html --allow-root"

echo -e "${GREEN}✅ WordPress đã được cài đặt thành công.${NC}"

# Xóa plugin mặc định
echo -e "${YELLOW}🧹 Đang dọn dẹp plugin mặc định...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "wp plugin delete hello akismet --path=/var/www/html --allow-root"
echo -e "${GREEN}✅ Plugin mặc định đã được xóa.${NC}"

# Cấu hình permalink
echo -e "${YELLOW}🔄 Cấu hình Permalink...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "wp option update permalink_structure '/%postname%/' --path=/var/www/html --allow-root"
echo -e "${GREEN}✅ Permalink đã được thiết lập.${NC}"

# Kiểm tra nếu Redis được chọn
if grep -q "WP_REDIS_HOST" "$WP_DIR/wp-config.php"; then
    echo -e "${YELLOW}🔄 Đang cài đặt plugin Redis Cache...${NC}"
    docker exec -i "$CONTAINER_PHP" sh -c "wp plugin install redis-cache --activate --path=/var/www/html --allow-root"
    docker exec -i "$CONTAINER_PHP" sh -c "wp redis enable --path=/var/www/html --allow-root"
    echo -e "${GREEN}✅ Redis Cache đã được kích hoạt.${NC}"
fi

# Cấu hình tối ưu bảo mật
echo -e "${YELLOW}🔐 Đang cấu hình bảo mật cho WordPress...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "wp option update blog_public 0 --path=/var/www/html --allow-root"
docker exec -i "$CONTAINER_PHP" sh -c "wp option update timezone_string 'Asia/Ho_Chi_Minh' --path=/var/www/html --allow-root"

echo -e "${GREEN}✅ WordPress đã được cài đặt thành công với bảo mật tối ưu.${NC}"
