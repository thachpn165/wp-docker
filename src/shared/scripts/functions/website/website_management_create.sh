# =====================================
# 🐋 website_management_create – Tạo website WordPress mới
# =====================================
# Load config và các hàm phụ thuộc
CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Không tìm thấy config.sh!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"

# ✅ Source hàm tạo file .env
source "$FUNCTIONS_DIR/website/website_create_env.sh"

# =====================================
# 🐋 website_management_create – Tạo website WordPress mới
# =====================================
website_management_create() {
  echo -e "${BLUE}===== TẠO WEBSITE WORDPRESS MỚi =====${NC}"

  # 🖊️ Nhập thông tin domain và site name
  read -p "Tên miền (ví dụ: example.com): " domain
  suggested_site_name=$(echo "$domain" | sed -E 's/\.[a-zA-Z]+$//')
  read -p "Tên site (mặc định: $suggested_site_name): " site_name
  site_name=${site_name:-$suggested_site_name}
  php_choose_version || return 1
  php_version="$REPLY"

  SITE_DIR="$SITES_DIR/$site_name"
  CONTAINER_PHP="${site_name}-php"
  CONTAINER_DB="${site_name}-mariadb"

  # ❌ Kiểm tra site đã tồn tại
  if is_directory_exist "$SITE_DIR" false; then
    echo -e "${RED}❌ Website '$site_name' đã tồn tại.${NC}"
    return 1
  fi

  # 📝 Tạo log
  mkdir -p "$LOGS_DIR"
  LOG_FILE="$LOGS_DIR/${site_name}-setup.log"
  touch "$LOG_FILE"
  exec > >(tee -a "$LOG_FILE") 2>&1
  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] BẮT ĐẦU TẠO SITE: $site_name =====" >> "$LOG_FILE"

  # 🧱 Tạo cấu trúc thư mục
  mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
  touch "$SITE_DIR/logs/access.log" "$SITE_DIR/logs/error.log"
  chmod 666 "$SITE_DIR/logs/"*.log

  # 🔧 Cấu hình NGINX
  update_nginx_override_mounts "$site_name"
  export site_name domain php_version
  bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"

  # ⚙️ Tạo cấu hình
  copy_file "$TEMPLATES_DIR/php.ini.template" "$SITE_DIR/php/php.ini"
  apply_mariadb_config "$SITE_DIR/mariadb/conf.d/custom.cnf"
  create_optimized_php_fpm_config "$SITE_DIR/php/php-fpm.conf"
  website_create_env "$SITE_DIR" "$site_name" "$domain" "$php_version"

  # 🛠️ Tạo docker-compose.yml
  TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
  TARGET_FILE="$SITE_DIR/docker-compose.yml"
  if is_file_exist "$TEMPLATE_FILE"; then
    set -o allexport && source "$SITE_DIR/.env" && set +o allexport
    envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE"
    echo -e "${GREEN}✅ Đã tạo docker-compose.yml${NC}"
  else
    echo -e "${RED}❌ Không tìm thấy template docker-compose.yml${NC}"
    return 1
  fi

  # 🚀 Khởi động container
  cd "$SITE_DIR"
  docker compose up -d

  echo -e "${YELLOW}⏳ Đang kiểm tra container khởi động...${NC}"
  for i in {1..30}; do
    if is_container_running "$CONTAINER_PHP" && is_container_running "$CONTAINER_DB"; then
      echo -e "${GREEN}✅ Container đã sẵn sàng.${NC}"
      break
    fi
    sleep 1
  done

  if ! is_container_running "$CONTAINER_PHP" || ! is_container_running "$CONTAINER_DB"; then
    echo -e "${RED}❌ Container chưa sẵn sàng sau 30 giây.${NC}"
    return 1
  fi

  # 🔐 Cài đặt SSL + WordPress
  generate_ssl_cert "$domain" "$SSL_DIR"
  cd "$BASE_DIR"
  bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh" "$site_name"

  # 📦 Hiển thị thông tin
  WP_INFO_FILE="$SITE_DIR/.wp-info"
  if [ -f "$WP_INFO_FILE" ]; then
    echo -e "${GREEN}\n🎉 WordPress đã được cài đặt thành công cho $site_name${NC}"
    cat "$WP_INFO_FILE"
    rm -f "$WP_INFO_FILE"
  fi

  # 🔁 Restart NGINX
  nginx_restart

  # 🧑‍🔧 Phân quyền
  if is_container_running "$CONTAINER_PHP"; then
    docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup /var/www/
  else
    echo -e "${YELLOW}⚠️ Container PHP chưa chạy, bỏ qua phân quyền.${NC}"
  fi

  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] ✅ HOÀN TẤT: $site_name =====" >> "$LOG_FILE"
}
