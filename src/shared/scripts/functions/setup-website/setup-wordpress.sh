#!/bin/bash

# =====================================
# 📣 Script cài đặt WordPress cho website đã tạo
# =====================================

set -euo pipefail

# 🔍 Load config
CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
  CONFIG_FILE="../$CONFIG_FILE"
  if [ "$(pwd)" = "/" ]; then
    echo "❌ Không tìm thấy config.sh" >&2
    exit 1
  fi
done
source "$CONFIG_FILE"

# ✉️ Nhận tham số site
site_name="${1:-}"
if [[ -z "$site_name" ]]; then
  echo -e "${RED}❌ Thiếu tham số tên site.${NC}"
  exit 1
fi

# 🗂️ Xác định thư mục chứa .env
SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"

# Nếu không tìm thấy trong sites/, thử tìm trong tmp/
if [[ ! -f "$ENV_FILE" ]]; then
  tmp_env_path=$(find "$TMP_DIR" -maxdepth 1 -type d -name "${site_name}_*" | head -n 1)
  if [[ -n "$tmp_env_path" && -f "$tmp_env_path/.env" ]]; then
    ENV_FILE="$tmp_env_path/.env"
    SITE_DIR="$tmp_env_path"
  else
    echo -e "${RED}❌ Không tìm thấy file .env cho site '$site_name'${NC}"
    exit 1
  fi
fi
ENV_FILE_DIR=$(dirname "$ENV_FILE")

# ↺ Load biến từ .env
DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")
PHP_VERSION=$(fetch_env_variable "$ENV_FILE" "PHP_VERSION")

# ⚖️ Container
PHP_CONTAINER="${site_name}-php"
DB_CONTAINER="${site_name}-mariadb"
SITE_URL="https://$DOMAIN"

# 🔐 Nhập thông tin quản trị
read -p "👤 Bạn có muốn hệ thống tự tạo tài khoản admin mạnh? [Y/n]: " auto_gen
auto_gen="${auto_gen:-Y}"
auto_gen="$(echo "$auto_gen" | tr '[:upper:]' '[:lower:]')"

if [[ "$auto_gen" == "n" ]]; then
  read -p "👤 Nhập tên người dùng admin: " ADMIN_USER
  while [[ -z "$ADMIN_USER" ]]; do
    echo "⚠️ Không được để trống."
    read -p "👤 Nhập tên người dùng admin: " ADMIN_USER
  done
  read -s -p "🔐 Nhập mật khẩu admin: " ADMIN_PASSWORD; echo
  read -s -p "🔐 Nhập lại mật khẩu: " CONFIRM_PASSWORD; echo
  while [[ "$ADMIN_PASSWORD" != "$CONFIRM_PASSWORD" || -z "$ADMIN_PASSWORD" ]]; do
    echo "⚠️ Mật khẩu không khớp hoặc rỗng. Vui lòng thử lại."
    read -s -p "🔐 Nhập mật khẩu admin: " ADMIN_PASSWORD; echo
    read -s -p "🔐 Nhập lại mật khẩu: " CONFIRM_PASSWORD; echo
  done
  read -p "📧 Nhập email admin (ENTER để dùng admin@$site_name.local): " ADMIN_EMAIL
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@$site_name.local}"
else
  ADMIN_USER="admin-$(openssl rand -base64 6 | tr -dc 'a-zA-Z0-9' | head -c 8)"
  ADMIN_PASSWORD="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)"
  ADMIN_EMAIL="admin@$site_name.local"
fi

# ✨ Thông báo bắt đầu
echo -e "${BLUE}▹ Bắt đầu cài đặt WordPress cho '$site_name'...${NC}"

# ⏳ Kiểm tra container PHP sẵn sàng
echo -e "${YELLOW}⏳ Đang chờ container PHP '$PHP_CONTAINER' khởi động...${NC}"
timeout=30
while ! is_container_running "$PHP_CONTAINER"; do
  sleep 1
  ((timeout--))
  if (( timeout <= 0 )); then
    echo -e "${RED}❌ Container PHP '$PHP_CONTAINER' không sẵn sàng sau 30s.${NC}"
    exit 1
  fi
  echo -ne "⏳ Đang chờ container PHP... ($((30-timeout))/30)\r"
done

# 📦 Tải mã nguồn WordPress nếu chưa có
if [[ ! -f "$SITE_DIR/wordpress/index.php" ]]; then
  echo -e "${YELLOW}📦 Đang tải WordPress...${NC}"

  # Kiểm tra thư mục đích trong container trước khi tải
  docker exec -i "$PHP_CONTAINER" sh -c "mkdir -p /var/www/html && chown -R nobody:nogroup /var/www/html"
  
  # Tải và giải nén WordPress vào thư mục đúng
  docker exec -i "$PHP_CONTAINER" sh -c "curl -o /var/www/html/wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
    tar -xzf /var/www/html/wordpress.tar.gz --strip-components=1 -C /var/www/html && rm /var/www/html/wordpress.tar.gz"

  echo -e "${GREEN}✅ Đã tải mã nguồn WordPress.${NC}"
else
  echo -e "${GREEN}✅ Mã nguồn WordPress đã có sẵn.${NC}"
fi

# ⚙️ Cài đặt wp-config
wp_set_wpconfig "$PHP_CONTAINER" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_CONTAINER"

# 🚀 Cài đặt WordPress
wp_install "$PHP_CONTAINER" "$SITE_URL" "$site_name" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

# 🛠️ Phân quyền & tối ưu
if is_container_running "$PHP_CONTAINER"; then
  docker exec -u root "$PHP_CONTAINER" chown -R nobody:nogroup "/var/www/" || {
    echo -e "${RED}❌ Phân quyền thất bại.${NC}"
    exit 1
  }
else
  echo -e "${RED}❌ Bỏ qua chown vì container chưa sẵn sàng.${NC}"
fi

wp_set_permalinks "$PHP_CONTAINER" "$SITE_URL"
# wp_plugin_install_performance_lab "$PHP_CONTAINER" # Bật nếu cần

# 📝 Ghi lại thông tin
cat > "$ENV_FILE_DIR/.wp-info" <<EOF
🌍 Website URL:   $SITE_URL
🔑 Admin URL:     $SITE_URL/wp-admin
👤 Admin User:    $ADMIN_USER
🔒 Admin Pass:    $ADMIN_PASSWORD
📧 Admin Email:   $ADMIN_EMAIL
EOF
