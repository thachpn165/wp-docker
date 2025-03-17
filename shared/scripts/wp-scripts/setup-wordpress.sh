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
CONTAINER_DB="${site_name}-mariadb"
SITE_URL="http://$site_name.local"
LOG_FILE="/var/log/wp-install.log"

# Tạo tài khoản admin ngẫu nhiên
ADMIN_USER="admin_$(openssl rand -hex 6)"
ADMIN_PASSWORD=$(openssl rand -base64 16)
ADMIN_EMAIL="admin@$site_name.local"

echo -e "${BLUE}🔹 Bắt đầu cài đặt WordPress cho '$site_name'...${NC}"

# **Kiểm tra tập tin .env**
if [ ! -f "$SITES_DIR/$site_name/.env" ]; then
    echo -e "${RED}❌ Lỗi: Không tìm thấy tập tin .env!${NC}"
    exit 1
fi

# **Lấy thông tin database từ .env**
DB_NAME=$(grep "MYSQL_DATABASE=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2 | tr -d '\r')
DB_USER=$(grep "MYSQL_USER=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2 | tr -d '\r')
DB_PASS=$(grep "MYSQL_PASSWORD=" "$SITES_DIR/$site_name/.env" | cut -d'=' -f2 | tr -d '\r')

# **Kiểm tra nếu biến rỗng**
if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
    echo -e "${RED}❌ Lỗi: Thông tin database chưa được thiết lập đúng!${NC}"
    exit 1
fi

# **Kiểm tra MySQL đã khởi động chưa**
echo -e "${YELLOW}⏳ Chờ MySQL khởi động...${NC}"
for i in {1..10}; do
    if docker exec "$CONTAINER_DB" sh -c 'mysqladmin ping -h localhost --silent'; then
        echo -e "${GREEN}✅ MySQL đã sẵn sàng.${NC}"
        break
    fi
    sleep 2
done

# **Escape ký tự đặc biệt trong `sed`**
DB_NAME_ESCAPED=$(printf '%s\n' "$DB_NAME" | sed 's/[\/&]/\\&/g')
DB_USER_ESCAPED=$(printf '%s\n' "$DB_USER" | sed 's/[\/&]/\\&/g')
DB_PASS_ESCAPED=$(printf '%s\n' "$DB_PASS" | sed 's/[\/&]/\\&/g')

# **Cấu hình wp-config.php bên trong container PHP**
echo -e "${YELLOW}⚙️ Cấu hình wp-config.php...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php && \
    sed -i 's/database_name_here/$DB_NAME_ESCAPED/' /var/www/html/wp-config.php && \
    sed -i 's/username_here/$DB_USER_ESCAPED/' /var/www/html/wp-config.php && \
    sed -i 's/password_here/$DB_PASS_ESCAPED/' /var/www/html/wp-config.php && \
    sed -i 's/localhost/$CONTAINER_DB/' /var/www/html/wp-config.php
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ wp-config.php đã được cấu hình thành công.${NC}"
else
    echo -e "${RED}❌ Lỗi khi cấu hình wp-config.php.${NC}"
    exit 1
fi

# **Cài đặt WordPress**
echo -e "${YELLOW}🚀 Đang cài đặt WordPress với WP-CLI...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    wp core install --url='$SITE_URL' --title='$site_name' --admin_user='$ADMIN_USER' --admin_password='$ADMIN_PASSWORD' --admin_email='$ADMIN_EMAIL' --path='/var/www/html' --allow-root
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ WordPress đã được cài đặt thành công.${NC}"
else
    echo -e "${RED}❌ Lỗi khi cài đặt WordPress.${NC}"
    exit 1
fi

# **Cấu hình Permalink**
echo -e "${YELLOW}🔄 Cấu hình Permalink...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "wp option update permalink_structure '/%postname%/' --allow-root --path=/var/www/html"

# **Tăng cường bảo mật**
echo -e "${YELLOW}🔐 Cấu hình bảo mật cho WordPress...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    wp option update blog_public 0 --allow-root --path=/var/www/html && \
    wp option update timezone_string 'Asia/Ho_Chi_Minh' --allow-root --path=/var/www/html
"

# **Hiển thị thông tin đăng nhập**
echo -e "\n\033[1;32m🚀 WordPress đã được cài đặt thành công! 🎉\033[0m"
echo -e "🔹 Truy cập website: \033[1;34m$SITE_URL\033[0m"
echo -e "🔹 Đăng nhập tại: \033[1;34m$SITE_URL/wp-admin\033[0m"
echo -e "🔹 Tài khoản admin: \033[1;33m$ADMIN_USER\033[0m"
echo -e "🔹 Mật khẩu admin: \033[1;31m$ADMIN_PASSWORD\033[0m"
echo -e "\n\033[1;32mLưu ý: Vui lòng lưu lại thông tin đăng nhập này!\033[0m\n"

# **Lưu thông tin vào log**
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WordPress installed - URL: $SITE_URL - Admin: $ADMIN_USER - Password: $ADMIN_PASSWORD" >> "$LOG_FILE"
