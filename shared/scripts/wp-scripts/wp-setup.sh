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

# 🛠️ Kiểm tra biến quan trọng có tồn tại không
required_vars=("PROJECT_ROOT" "SITES_DIR" "WP_SCRIPTS_DIR" "DOCKER_NETWORK" "NGINX_PROXY_CONTAINER" "SSL_DIR")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
        exit 1
    fi
done

# 📌 Nhận tham số đầu vào (tên website)
if [ -z "$1" ]; then
    echo -e "${RED}❌ Lỗi: Chưa nhập tên website.${NC}"
    exit 1
fi

# 🏗️ Định nghĩa các biến hệ thống
site_name="$1"
SITE_DIR="$SITES_DIR/$site_name"
WP_DIR="$SITE_DIR/wordpress"
ENV_FILE="$SITE_DIR/.env"
CONTAINER_PHP="${site_name}-php"
CONTAINER_DB="${site_name}-mariadb"

# 📌 Kiểm tra và tải biến từ .env
if is_file_exist "$ENV_FILE"; then
    DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
fi

# 🌐 Xác định URL website
if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}⚠️ Không tìm thấy biến DOMAIN trong .env, sử dụng mặc định http://$site_name.local${NC}"
    SITE_URL="http://$site_name.local"
else
    SITE_URL="https://$DOMAIN"
fi

# 🔑 Tạo tài khoản admin ngẫu nhiên
ADMIN_USER="admin_$(openssl rand -hex 6)"
ADMIN_PASSWORD=$(openssl rand -base64 16)
ADMIN_EMAIL="admin@$site_name.local"

echo -e "${BLUE}🔹 Bắt đầu cài đặt WordPress cho '$site_name'...${NC}"

# ⏳ Chờ container PHP khởi động
echo -e "${YELLOW}⏳ Chờ container PHP '$CONTAINER_PHP' khởi động...${NC}"
sleep 10

if ! is_container_running "$CONTAINER_PHP"; then
    echo -e "${RED}❌ Lỗi: Container PHP '$CONTAINER_PHP' chưa chạy. Hãy kiểm tra lại!${NC}"
    exit 1
fi

# 📥 Kiểm tra và tải WP-CLI nếu chưa có
check_and_install_wp_cli "$CONTAINER_PHP"

# 📂 Kiểm tra và tải mã nguồn WordPress
if [ ! -f "$WP_DIR/index.php" ]; then
    echo -e "${YELLOW}📥 Đang tải WordPress...${NC}"
    mkdir -p "$WP_DIR"
    docker exec -i "$CONTAINER_PHP" sh -c "
        curl -o wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
        tar -xzf wordpress.tar.gz --strip-components=1 -C /var/www/html && \
        rm wordpress.tar.gz
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ WordPress đã được tải xuống thành công.${NC}"
    else
        echo -e "${RED}❌ Lỗi khi tải mã nguồn WordPress.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Mã nguồn WordPress đã có sẵn, bỏ qua bước tải xuống.${NC}"
fi

# 📋 Lấy thông tin database từ .env
DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")

if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
    echo -e "${RED}❌ Lỗi: Biến môi trường MySQL không hợp lệ trong .env!${NC}"
    exit 1
fi

# ⏳ Chờ MySQL khởi động
echo -e "${YELLOW}⏳ Chờ MySQL khởi động...${NC}"
for i in {1..10}; do
    if is_container_running "$CONTAINER_DB" && docker exec "$CONTAINER_DB" sh -c 'mysqladmin ping -h localhost --silent'; then
        echo -e "${GREEN}✅ MySQL đã sẵn sàng.${NC}"
        break
    fi
    sleep 2
done

# 🛠️ Cấu hình wp-config.php
setup_wp_config "$CONTAINER_PHP" "$DB_NAME" "$DB_USER" "$DB_PASS" "$CONTAINER_DB"

# 🚀 Cài đặt WordPress
install_wordpress "$CONTAINER_PHP" "$SITE_URL" "$site_name" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

echo -e "${GREEN}🎉 Hoàn tất quá trình cài đặt WordPress tại $SITE_URL.${NC}"
echo -e "${YELLOW}🔐 Tài khoản admin: $ADMIN_USER / $ADMIN_PASSWORD${NC}"
