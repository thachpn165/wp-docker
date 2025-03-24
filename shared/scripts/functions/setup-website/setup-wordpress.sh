#!/bin/bash

# ✅ Cài đặt WordPress cho website đã tạo

CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
  CONFIG_FILE="../$CONFIG_FILE"
  if [ "$(pwd)" = "/" ]; then
    echo "❌ Không tìm thấy config.sh" >&2
    exit 1
  fi
done
source "$CONFIG_FILE"

# 📌 Nhận tên site
site_name="$1"
if [ -z "$site_name" ]; then
    echo -e "${RED}❌ Thiếu tham số tên site.${NC}"
    exit 1
fi

# 🏗️ Xác định các biến
SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"
PHP_CONTAINER="$site_name-php"
DB_CONTAINER="$site_name-mariadb"

# 📋 Load biến từ .env
if is_file_exist "$ENV_FILE"; then
    DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
    DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
    DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
    DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")
else
    echo -e "${RED}❌ Không tìm thấy file .env${NC}"
    exit 1
fi

SITE_URL="https://$DOMAIN"

# 🔐 Tạo thông tin admin
ADMIN_USER="admin-$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)"
ADMIN_PASSWORD="$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)"
ADMIN_EMAIL="admin@$site_name.local"

echo -e "${BLUE}🔹 Bắt đầu cài đặt WordPress cho '$site_name'...${NC}"

# ⏳ Chờ container PHP sẵn sàng
sleep 10
if ! is_container_running "$PHP_CONTAINER"; then
    echo -e "${RED}❌ Container PHP chưa sẵn sàng.${NC}"
    exit 1
fi

# 📦 Tải WordPress nếu chưa có
if [ ! -f "$SITE_DIR/wordpress/index.php" ]; then
    echo -e "${YELLOW}📥 Đang tải mã nguồn WordPress...${NC}"
    docker exec -i "$PHP_CONTAINER" sh -c "curl -o wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
        tar -xzf wordpress.tar.gz --strip-components=1 -C /var/www/html && rm wordpress.tar.gz"
    echo -e "${GREEN}✅ WordPress đã được tải xuống.${NC}"
else
    echo -e "${GREEN}✅ Mã nguồn WordPress đã có sẵn.${NC}"
fi

# ⚙️ Thiết lập wp-config.php
wp_set_wpconfig "$PHP_CONTAINER" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_CONTAINER"

# 🚀 Cài đặt WordPress
wp_install "$PHP_CONTAINER" "$SITE_URL" "$site_name" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

# 🔁 Cấu hình permalinks
wp_set_permalinks "$PHP_CONTAINER" "$SITE_URL"

# 🔌 Cài plugin hiệu năng
wp_plugin_install_performance_lab "$PHP_CONTAINER"

# 📋 Ghi file .wp-info
cat > "$SITE_DIR/.wp-info" <<EOF
🌍 Website URL:   $SITE_URL
🔑 Admin URL:     $SITE_URL/wp-admin
👤 Admin User:    $ADMIN_USER
🔒 Admin Pass:    $ADMIN_PASSWORD
📧 Admin Email:   $ADMIN_EMAIL
EOF