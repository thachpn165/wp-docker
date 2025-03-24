#!/bin/bash

# =====================================
# 🐳 Script tạo website WordPress mới
# =====================================

set -euo pipefail

CONFIG_FILE="shared/config/config.sh"

# 🔍 Tìm file config.sh theo thứ tự thư mục cha nếu chưa thấy
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"
source "$SCRIPTS_FUNCTIONS_DIR/nginx_utils.sh"
SETUP_WORDPRESS_SCRIPT="$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh"

# ✅ Kiểm tra các biến cấu hình bắt buộc
required_vars=(
  "PROJECT_ROOT" "SITES_DIR" "TEMPLATES_DIR" "CONFIG_DIR" "SCRIPTS_DIR"
  "FUNCTIONS_DIR" "WP_SCRIPTS_DIR" "WEBSITE_MGMT_DIR" "NGINX_PROXY_DIR"
  "NGINX_SCRIPTS_DIR" "SSL_DIR" "DOCKER_NETWORK" "NGINX_PROXY_CONTAINER"
  "SETUP_WORDPRESS_SCRIPT"
)
check_required_envs "${required_vars[@]}"

HOST_UID=$(id -u)

echo -e "${BLUE}===== TẠO WEBSITE WORDPRESS MỚI =====${NC}"

# 📅 Nhập thông tin người dùng
read -p "Tên miền (ví dụ: example.com): " domain
suggested_site_name=$(echo "$domain" | sed -E 's/\.[a-zA-Z]+$//')
read -p "Tên site (mặc định: $suggested_site_name): " site_name
site_name=${site_name:-$suggested_site_name}
read -p "Chọn phiên bản PHP (7.4, 8.1, 8.3) [mặc định: 8.3]: " php_version
php_version=${php_version:-8.3}

# 📝 Ghi log quá trình tại thư mục /logs
LOG_FILE="$PROJECT_ROOT/logs/${site_name}-setup.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# ⏰ Thời gian bắt đầu
start_time=$(date '+%Y-%m-%d %H:%M:%S')
echo -e "${YELLOW}📄 Đang ghi log quá trình vào: $LOG_FILE${NC}"
echo "===== [ $start_time ] Bắt ĐầU TẠO WEBSITE: $site_name ($domain) =====" >> "$LOG_FILE"

# ↺ Ghi toàn bộ output (stdout + stderr) vào file log
exec > >(tee -a "$LOG_FILE") 2>&1

SITE_DIR="$SITES_DIR/$site_name"
TMP_SITE_DIR="$PROJECT_ROOT/tmp/${site_name}_$RANDOM"
CONTAINER_PHP="${site_name}-php"

# 🔐 Xử lý dịv tạo thư mục tạm nếu site đã tồn tại
if is_directory_exist "$SITE_DIR" false; then
    echo "❌ Website '$site_name' đã tồn tại. Vui lòng chọn tên khác."
    exit 1
fi

# ♻ Cleanup khi lỗi
cleanup_on_fail() {
    echo -e "${RED}❌ Có lỗi xảy ra. Đang xoá thư mục tạm $TMP_SITE_DIR...${NC}"
    rm -rf "$TMP_SITE_DIR"
    echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] ❌ XOÁ SITE DO THẤT BẠI =====" >> "$LOG_FILE"
    exit 1
}
trap cleanup_on_fail ERR

# 📂 Tạo thư mục tạm
mkdir -p "$TMP_SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
touch "$TMP_SITE_DIR/logs/access.log" "$TMP_SITE_DIR/logs/error.log"
chmod 666 "$TMP_SITE_DIR/logs/"*.log

# ⚙️ docker-compose.override.yml
update_nginx_override_mounts "$site_name"

# 🌐 Tạo file cấu hình nginx
export site_name domain php_version
SITE_DIR="$TMP_SITE_DIR"
bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"
SITE_DIR="$SITES_DIR/$site_name"

# 📋 php.ini, mariadb, php-fpm
copy_file "$TEMPLATES_DIR/php.ini.template" "$TMP_SITE_DIR/php/php.ini"
echo -e "${YELLOW}⚙️ Đang tạo cấu hình MariaDB tối ưu...${NC}"
apply_mariadb_config "$TMP_SITE_DIR/mariadb/conf.d/custom.cnf"
echo -e "${YELLOW}⚙️ Đang tạo cấu hình PHP-FPM tối ưu...${NC}"
create_optimized_php_fpm_config "$TMP_SITE_DIR/php/php-fpm.conf"

# 🔐 .env
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
MYSQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
cat > "$TMP_SITE_DIR/.env" <<EOF
SITE_NAME=$site_name
DOMAIN=$domain
PHP_VERSION=$php_version
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF

# 📅 docker-compose.yml
TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
TARGET_FILE="$TMP_SITE_DIR/docker-compose.yml"
if is_file_exist "$TEMPLATE_FILE"; then
    set -o allexport && source "$TMP_SITE_DIR/.env" && set +o allexport
    envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE"
    echo -e "${GREEN}✅ File docker-compose.yml đã được tạo.${NC}"
else
    echo -e "${RED}❌ Không tìm thấy template docker-compose.yml${NC}"
    exit 1
fi

# 🚀 Khởi động container
cd "$TMP_SITE_DIR"
docker compose up -d

# 🔐 SSL self-signed
generate_ssl_cert "$domain" "$SSL_DIR"

# ⚙️ Cài đặt WordPress
bash "$SETUP_WORDPRESS_SCRIPT" "$site_name"

# 🔄 Reload & chown
restart_nginx_proxy
docker exec -u root "$NGINX_PROXY_CONTAINER" chown -R nobody:nogroup "/var/www/$site_name"
docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup "/var/www/"

# 📋 Hiển thị thông tin
WP_INFO_FILE="$TMP_SITE_DIR/.wp-info"
if [ -f "$WP_INFO_FILE" ]; then
    echo -e "${GREEN}\n==================================================="
    echo -e "🎉 WordPress đã được cài đặt thành công! 🎉"
    echo -e "===================================================${NC}"
    while read -r line; do
        echo -e "${YELLOW}$line${NC}"
    done < "$WP_INFO_FILE"
    echo -e "${GREEN}==================================================="
    echo -e "🚀 Hãy truy cập website của bạn ngay bây giờ!"
    echo -e "===================================================${NC}"
    rm -f "$WP_INFO_FILE"
fi

# 📅 Hoàn tất & di chuyển site vào sites/
mv "$TMP_SITE_DIR" "$SITE_DIR"
echo -e "${GREEN}✅ Website đã được di chuyển từ tmp/ vào: $SITE_DIR${NC}"

end_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "===== [ $end_time ] HOÀN THÀNH TẠO WEBSITE: $site_name =====" >> "$LOG_FILE"
