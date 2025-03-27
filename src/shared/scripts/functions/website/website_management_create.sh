# =====================================
# 🐋 website_management_create – Tạo website WordPress mới
# =====================================


# === 🧠 Tự động xác định PROJECT_DIR (gốc mã nguồn) ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# === ✅ Load config.sh từ PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Không tìm thấy config.sh tại: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"

# Load config và các hàm phụ thuộc
source "$FUNCTIONS_DIR/website/website_create_env.sh"

# =====================================
# 🐋 website_management_create – Tạo website WordPress mới
# =====================================
website_management_create() {
  
  echo -e "${BLUE}===== TẠO WEBSITE WORDPRESS MỚi =====${NC}"

  # 📥 Nhập domain và tên site
  domain="$(get_input_or_test_value "Tên miền (ví dụ: example.com): " "${TEST_DOMAIN:-example.com}")"
  suggested_site_name=$(echo "$domain" | sed -E 's/\.[a-zA-Z]+$//')
  site_name="$(get_input_or_test_value "Tên site (mặc định: $suggested_site_name): " "${TEST_SITE_NAME:-$suggested_site_name}")"
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
  run_unless_test exec > >(tee -a "$LOG_FILE") 2>&1
  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] BẮT ĐẦU TẠO SITE: $site_name =====" >> "$LOG_FILE"

  # 🧱 Tạo cấu trúc thư mục
  mkdir -p "$SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
  touch "$SITE_DIR/logs/access.log" "$SITE_DIR/logs/error.log"
  chmod 666 "$SITE_DIR/logs/"*.log

  # 🔧 Cấu hình NGINX
  update_nginx_override_mounts "$site_name"
  export site_name domain php_version
  run_unless_test bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"

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
  run_unless_test run_in_dir "$SITE_DIR" docker compose up -d

  echo -e "${YELLOW}⏳ Đang kiểm tra container khởi động...${NC}"
  for i in {1..30}; do
    if is_container_running "$CONTAINER_PHP" && is_container_running "$CONTAINER_DB"; then
      echo -e "${GREEN}✅ Container đã sẵn sàng.${NC}"
      break
    fi
    run_unless_test sleep 1
  done

  if ! is_container_running "$CONTAINER_PHP" || ! is_container_running "$CONTAINER_DB"; then
    echo -e "${RED}❌ Container chưa sẵn sàng sau 30 giây.${NC}"
    return 1
  fi

  # 🔐 Cài đặt SSL + WordPress
  generate_ssl_cert "$domain" "$SSL_DIR"
  run_unless_test bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh" "$site_name"

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
    run_unless_test docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup /var/www/
  else
    echo -e "${YELLOW}⚠️ Container PHP chưa chạy, bỏ qua phân quyền.${NC}"
  fi

  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] ✅ HOÀN TẤT: $site_name =====" >> "$LOG_FILE"
}
