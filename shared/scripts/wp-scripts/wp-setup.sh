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

# 📌 Nhận tham số đầu vào (tên website)
if [ -z "$1" ]; then
    echo -e "${RED}❌ Lỗi: Chưa nhập tên website.${NC}"
    exit 1
fi

# 🏗️ Định nghĩa các biến hệ thống
site_name="$1"
SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"
CONTAINER_PHP="${site_name}-php"
CONTAINER_DB="${site_name}-mariadb"

# 📋 Lấy thông tin từ .env
if is_file_exist "$ENV_FILE"; then
    DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
fi

# 🌍 Xác định URL website
if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}⚠️ Không tìm thấy biến DOMAIN trong .env, sử dụng mặc định https://$site_name.local${NC}"
    SITE_URL="https://$site_name.local"
else
    SITE_URL="https://$DOMAIN"
fi

# 🔑 Tạo tài khoản admin ngẫu nhiên
ADMIN_USER="admin-$(openssl rand -base64 12)"
ADMIN_PASSWORD=$(openssl rand -base64 12)
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
if [ ! -f "$SITE_DIR/wordpress/index.php" ]; then
    echo -e "${YELLOW}📥 Đang tải WordPress...${NC}"
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

# 🛠️ Cấu hình wp-config.php
wp_set_wpconfig "$CONTAINER_PHP" "$DB_NAME" "$DB_USER" "$DB_PASS" "$CONTAINER_DB"

# 🚀 Cài đặt WordPress
wp_install "$CONTAINER_PHP" "$SITE_URL" "$site_name" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

# 🛠️ **Thiết lập permalinks**
wp_set_permalinks "$CONTAINER_PHP" "$SITE_URL"

# Cài đặt plugin PerformanceLab và bật tính năng WebP
wp_plugin_install_performance_lab "$CONTAINER_PHP"

# Cài đặt plugin bảo mật
wp_plugin_install_security_plugin "$CONTAINER_PHP"

# Kiểm tra user có trong nhóm www-data chưa
if ! groups $USER | grep -q "\bwww-data\b"; then
    echo -e "${YELLOW}🔹 Thêm user hiện tại vào nhóm www-data...${NC}"
    sudo usermod -aG www-data $USER
    echo -e "${GREEN}✅ Vui lòng đăng xuất và đăng nhập lại để áp dụng quyền.${NC}"
fi

# 🎉 **Hiển thị thông tin đăng nhập đẹp mắt**
echo -e "${GREEN}"
echo -e "==================================================="
echo -e "🎉 WordPress đã được cài đặt thành công! 🎉"
echo -e "==================================================="
echo -e "🌍 Website URL:   ${CYAN}$SITE_URL${GREEN}"
echo -e "🔑 Admin URL:     ${CYAN}$SITE_URL/wp-admin${GREEN}"
echo -e "👤 Admin User:    ${YELLOW}$ADMIN_USER${GREEN}"
echo -e "🔒 Admin Pass:    ${YELLOW}$ADMIN_PASSWORD${GREEN}"
echo -e "📧 Admin Email:   ${YELLOW}$ADMIN_EMAIL${GREEN}"
echo -e "==================================================="
echo -e "🚀 Hãy truy cập website của bạn ngay bây giờ!"
echo -e "==================================================="
echo -e "${NC}"
