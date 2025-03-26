# =====================================
# 🐳 website_management_create – Tạo website WordPress mới
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

website_management_create() {
  HOST_UID=$(id -u)

  echo -e "${BLUE}===== TẠO WEBSITE WORDPRESS MỘi =====${NC}"

  read -p "Tên miên (ví dụ: example.com): " domain
  suggested_site_name=$(echo "$domain" | sed -E 's/\.[a-zA-Z]+$//')
  read -p "Tên site (mặc định: $suggested_site_name): " site_name
  site_name=${site_name:-$suggested_site_name}

  # Kiểm tra xem site đã tồn tại chưa
  if is_directory_exist "$SITE_DIR" false; then
    echo "❌ Website '$site_name' đã tồn tại. Vui lòng chọn tên khác."
    return 1
  fi

  php_choose_version || return 1
  php_version="$REPLY"

  mkdir -p "$LOGS_DIR"
  LOG_FILE="$LOGS_DIR/${site_name}-setup.log"
  touch "$LOG_FILE"

  start_time=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${YELLOW}📄 Đang ghi log quá trình vào: $LOG_FILE${NC}"
  echo "===== [ $start_time ] Bắt Đầu TẠO WEBSITE: $site_name ($domain) =====" >> "$LOG_FILE"

  exec > >(tee -a "$LOG_FILE") 2>&1

  SITE_DIR="$SITES_DIR/$site_name"
  mkdir -p "$TMP_DIR"
  TMP_SITE_DIR="$TMP_DIR/${site_name}_$RANDOM"
  CONTAINER_PHP="${site_name}-php"


  cleanup_on_fail() {
    echo -e "${RED}❌ Có lỗi xảy ra. Đang xoá thư mục tạm $TMP_SITE_DIR và container liên quan...${NC}"
    docker stop "$CONTAINER_PHP" "${site_name}-mariadb" &>/dev/null || true
    docker rm "$CONTAINER_PHP" "${site_name}-mariadb" &>/dev/null || true
    rm -rf "$TMP_SITE_DIR"
    echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] ❌ XOÁ SITE DO THẤT BẠI =====" >> "$LOG_FILE"
    return 1
  }
  trap cleanup_on_fail ERR

  mkdir -p "$TMP_SITE_DIR"/{php,mariadb/conf.d,wordpress,logs,backups}
  touch "$TMP_SITE_DIR/logs/access.log" "$TMP_SITE_DIR/logs/error.log"
  chmod 666 "$TMP_SITE_DIR/logs/"*.log

  update_nginx_override_mounts "$site_name"
  export site_name domain php_version
  SITE_DIR="$TMP_SITE_DIR"
  bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"
  SITE_DIR="$SITES_DIR/$site_name"

  copy_file "$TEMPLATES_DIR/php.ini.template" "$TMP_SITE_DIR/php/php.ini"
  echo -e "${YELLOW}⚙️ Đang tạo cấu hình MariaDB tối ưu...${NC}"
  apply_mariadb_config "$TMP_SITE_DIR/mariadb/conf.d/custom.cnf"
  echo -e "${YELLOW}⚙️ Đang tạo cấu hình PHP-FPM tối ưu...${NC}"
  create_optimized_php_fpm_config "$TMP_SITE_DIR/php/php-fpm.conf"

  website_create_env "$TMP_SITE_DIR" "$site_name" "$domain" "$php_version"

  TEMPLATE_FILE="$TEMPLATES_DIR/docker-compose.yml.template"
  TARGET_FILE="$TMP_SITE_DIR/docker-compose.yml"
  if is_file_exist "$TEMPLATE_FILE"; then
    set -o allexport && source "$TMP_SITE_DIR/.env" && set +o allexport
    envsubst < "$TEMPLATE_FILE" > "$TARGET_FILE"
    echo -e "${GREEN}✅ File docker-compose.yml đã được tạo.${NC}"
  else
    echo -e "${RED}❌ Không tìm thấy template docker-compose.yml${NC}"
    return 1
  fi

  cd "$TMP_SITE_DIR"
  docker compose up -d

  generate_ssl_cert "$domain" "$SSL_DIR"
  cd "$BASE_DIR"
  bash "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh" "$site_name"

  WP_INFO_FILE="$TMP_SITE_DIR/.wp-info"
  if [ -f "$WP_INFO_FILE" ]; then
    echo -e "${GREEN}\n==================================================="
    echo -e "🎉 WordPress đã được cài đặt thành công! 🎉"
    echo -e "${RED} LƯU Ý: HÃY LƯU LẠI THÔNG TIN BÊN DƯỚi${NC}"
    echo -e "===================================================${NC}"
    while read -r line; do
      echo -e "${YELLOW}$line${NC}"
    done < "$WP_INFO_FILE"
    rm -f "$WP_INFO_FILE"
  fi

  mkdir -p "$SITE_DIR"
  shopt -s dotglob
  mv "$TMP_SITE_DIR"/* "$SITE_DIR"/
  shopt -u dotglob
  rm -rf "$TMP_SITE_DIR"
  echo -e "${GREEN}✅ Website đã được di chuyển từ tmp/ vào: $SITE_DIR${NC}"

  cd "$SITE_DIR"
  docker compose up -d
  sleep 5
  nginx_restart

  if is_container_running "$CONTAINER_PHP"; then
    docker exec -u root "$NGINX_PROXY_CONTAINER" chown -R nobody:nogroup "/var/www/$site_name"
    docker exec -u root "$CONTAINER_PHP" chown -R nobody:nogroup "/var/www/"
  else
    echo -e "${RED}❌ Container PHP '$CONTAINER_PHP' chưa khởi động. Bỏ qua chown...${NC}"
  fi

  echo "===== [ $(date '+%Y-%m-%d %H:%M:%S') ] HOÀN THÀNH TẠO WEBSITE: $site_name =====" >> "$LOG_FILE"
}
