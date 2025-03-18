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
# Import config.sh từ thư mục cha (shared/scripts/)
source "$(cd "$(dirname "$0")" && cd .. && pwd)/config.sh"
SITES_DIR="$PROJECT_ROOT/sites"
SITE_DIR="$SITES_DIR/$site_name"
WP_DIR="$SITE_DIR/wordpress"
ENV_FILE="$SITE_DIR/.env"
CONTAINER_PHP="${site_name}-php"
CONTAINER_DB="${site_name}-mariadb"
SITE_URL="https://$DOMAIN"


# Tạo tài khoản admin ngẫu nhiên
ADMIN_USER="admin_$(openssl rand -hex 6)"
ADMIN_PASSWORD=$(openssl rand -base64 16)
ADMIN_EMAIL="admin@$site_name.local"

echo -e "${BLUE}🔹 Bắt đầu cài đặt WordPress cho '$site_name'...${NC}"

# **Kiểm tra xem container PHP đã khởi động chưa**
echo -e "${YELLOW}⏳ Chờ container PHP '$CONTAINER_PHP' khởi động...${NC}"
sleep 10

if ! docker ps --format '{{.Names}}' | grep -q "$CONTAINER_PHP"; then
    echo -e "${RED}❌ Lỗi: Container PHP '$CONTAINER_PHP' chưa chạy. Hãy kiểm tra lại!${NC}"
    exit 1
fi



# **Tải WordPress nếu chưa có**
echo -e "${YELLOW}📥 Đang kiểm tra mã nguồn WordPress...${NC}"
if [ ! -f "$WP_DIR/index.php" ]; then
    echo -e "${YELLOW}📥 Đang tải WordPress...${NC}"
    mkdir -p "$WP_DIR"
    docker exec -i "$CONTAINER_PHP" sh -c "curl -o wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && tar -xzf wordpress.tar.gz --strip-components=1 -C /var/www/html && rm wordpress.tar.gz"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ WordPress đã được tải xuống thành công.${NC}"
    else
        echo -e "${RED}❌ Lỗi khi tải mã nguồn WordPress.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Mã nguồn WordPress đã có sẵn, bỏ qua bước tải xuống.${NC}"
fi


# **Lấy thông tin database từ .env**
DB_NAME=$(grep -E "^MYSQL_DATABASE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\r')
DB_USER=$(grep -E "^MYSQL_USER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\r')
DB_PASS=$(grep -E "^MYSQL_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\r')

# **Kiểm tra nếu biến rỗng**
if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
    echo -e "${RED}❌ Lỗi: Biến môi trường MySQL không hợp lệ trong .env!${NC}"
    exit 1
fi

# **Chờ MySQL khởi động trước khi tiến hành cài đặt**
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

# **Kiểm tra và cài đặt WP-CLI trong container PHP**
echo -e "${YELLOW}🔄 Kiểm tra và cài đặt WP-CLI nếu chưa có...${NC}"
docker exec -i "$CONTAINER_PHP" sh -c "
    if ! command -v wp > /dev/null; then
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
        chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
    fi
"

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

# **Hiển thị thông tin đăng nhập**
echo -e "\n\033[1;32m🚀 WordPress đã được cài đặt thành công! 🎉\033[0m"
echo -e "🔹 Truy cập website: \033[1;34m$SITE_URL\033[0m"
echo -e "🔹 Đăng nhập tại: \033[1;34m$SITE_URL/wp-admin\033[0m"
echo -e "🔹 Tài khoản admin: \033[1;33m$ADMIN_USER\033[0m"
echo -e "🔹 Mật khẩu admin: \033[1;31m$ADMIN_PASSWORD\033[0m"
echo -e "\n\033[1;32mLưu ý: Vui lòng lưu lại thông tin đăng nhập này!\033[0m\n"


