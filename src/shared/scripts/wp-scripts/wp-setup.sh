#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Xác định đường dẫn tuyệt đối của `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "${CROSSMARK} Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# 📌 Nhận tham số đầu vào (tên website)
if [ -z "$1" ]; then
    echo -e "${RED}${CROSSMARK} Lỗi: Chưa nhập tên website.${NC}"
    exit 1
fi

# 🏗️ Định nghĩa các biến hệ thống
site_name="$1"
SITE_DIR="$SITES_DIR/$domain"
ENV_FILE="$SITE_DIR/.env"
CONTAINER_PHP="${domain}-php"
CONTAINER_DB="${domain}-mariadb"

# 📋 Lấy thông tin từ .env
if is_file_exist "$ENV_FILE"; then
    DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
fi

# 🌍 Xác định URL website
if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}${WARNING} Không tìm thấy biến DOMAIN trong .env, sử dụng mặc định https://$domain.local${NC}"
    SITE_URL="https://$domain.local"
else
    SITE_URL="https://$DOMAIN"
fi

# 🔑 Tạo tài khoản admin ngẫu nhiên
ADMIN_USER="admin-$(openssl rand -base64 12)"
ADMIN_PASSWORD=$(openssl rand -base64 12)
ADMIN_EMAIL="admin@$domain.local"

echo -e "${BLUE}🔹 Bắt đầu cài đặt WordPress cho '$domain'...${NC}"

# ⏳ Chờ container PHP khởi động
echo -e "${YELLOW}⏳ Chờ container PHP '$CONTAINER_PHP' khởi động...${NC}"
sleep 10

if ! is_container_running "$CONTAINER_PHP"; then
    echo -e "${RED}${CROSSMARK} Lỗi: Container PHP '$CONTAINER_PHP' chưa chạy. Hãy kiểm tra lại!${NC}"
    exit 1
fi

# 📥 Kiểm tra và tải WP-CLI nếu chưa có
#check_and_install_wp_cli "$CONTAINER_PHP"

# 📂 Kiểm tra và tải mã nguồn WordPress
if [ ! -f "$SITE_DIR/wordpress/index.php" ]; then
    echo -e "${YELLOW}📥 Đang tải WordPress...${NC}"
    docker exec -i "$CONTAINER_PHP" sh -c " || { echo "${CROSSMARK} Command failed at line 64"; exit 1; }
        curl -o wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
        tar -xzf wordpress.tar.gz --strip-components=1 -C /var/www/html && \
        rm wordpress.tar.gz || { echo "${CROSSMARK} Command failed at line 67"; exit 1; }
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${CHECKMARK} WordPress đã được tải xuống thành công.${NC}"
    else
        echo -e "${RED}${CROSSMARK} Lỗi khi tải mã nguồn WordPress.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}${CHECKMARK} Mã nguồn WordPress đã có sẵn, bỏ qua bước tải xuống.${NC}"
fi

# 📋 Lấy thông tin database từ .env
DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")

if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
    echo -e "${RED}${CROSSMARK} Lỗi: Biến môi trường MySQL không hợp lệ trong .env!${NC}"
    exit 1
fi

# 🛠️ Cấu hình wp-config.php
wp_set_wpconfig "$CONTAINER_PHP" "$DB_NAME" "$DB_USER" "$DB_PASS" "$CONTAINER_DB"

# 🚀 Cài đặt WordPress
wp_install "$CONTAINER_PHP" "$SITE_URL" "$domain" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

# 🛠️ **Thiết lập permalinks**
wp_set_permalinks "$CONTAINER_PHP" "$SITE_URL"

# Cài đặt plugin PerformanceLab và bật tính năng WebP
wp_plugin_install_performance_lab "$CONTAINER_PHP"

# Cài đặt plugin bảo mật
#wp_plugin_install_security_plugin "$CONTAINER_PHP"

# 🎉 **Hiển thị thông tin đăng nhập đẹp mắt**
cat > "$SITE_DIR/.wp-info" <<EOF
🌍 Website URL:   $SITE_URL
🔑 Admin URL:     $SITE_URL/wp-admin
👤 Admin User:    $ADMIN_USER
🔒 Admin Pass:    $ADMIN_PASSWORD
📧 Admin Email:   $ADMIN_EMAIL
EOF