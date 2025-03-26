# =====================================
# 🗑️ website_management_delete – Xóa một website WordPress
# =====================================

website_management_delete() {
  echo -e "${YELLOW}📋 Danh sách các website có thể xóa:${NC}"
  site_list=( $(ls -1 "$SITES_DIR") )

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để xóa.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  read -p "Nhập số tương ứng với website cần xóa: " site_index
  site_name="${site_list[$site_index]}"
  SITE_DIR="$SITES_DIR/$site_name"
  ENV_FILE="$SITE_DIR/.env"

  if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}❌ Website '$site_name' không tồn tại.${NC}"
    return 1
  fi

  if ! is_file_exist "$ENV_FILE"; then
    echo -e "${RED}❌ Không tìm thấy file .env của website!${NC}"
    return 1
  fi

  DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
  MARIADB_VOLUME="${site_name}_mariadb_data"
  SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$site_name.conf"

  echo -e "${RED}${BOLD}🚨 CẢNH BÁO QUAN TRỌNG 🚨${NC}"
  echo -e "${RED}❗ Việc xóa website là KHÔNG THỂ HOÀN TÁC ❗${NC}"
  echo -e "${YELLOW}📌 Hãy backup dữ liệu trước khi tiếp tục.${NC}"

  if ! confirm_action "⚠️ Bạn có chắc muốn xóa website '$site_name' ($DOMAIN)?"; then
    echo -e "${YELLOW}⚠️ Đã hủy thao tác xóa.${NC}"
    return 1
  fi

  # 🧰 Gợi ý sao lưu nếu cần
  if confirm_action "💾 Bạn có muốn sao lưu mã nguồn và database trước khi xoá không?"; then
    ARCHIVE_DIR="$ARCHIVES_DIR/old_website/${site_name}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$ARCHIVE_DIR"

    DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
    DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
    DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")

    if [[ -n "$DB_NAME" && -n "$DB_USER" && -n "$DB_PASS" ]]; then
      echo -e "${YELLOW}📦 Đang backup database...${NC}"
      docker exec "${site_name}-mariadb" sh -c "exec mysqldump -u$DB_USER -p\"$DB_PASS\" $DB_NAME" \
        > "$ARCHIVE_DIR/${site_name}_db.sql" 2>/dev/null || true
    fi

    echo -e "${YELLOW}📦 Đang nén mã nguồn WordPress...${NC}"
    tar -czf "$ARCHIVE_DIR/${site_name}_wordpress.tar.gz" -C "$SITE_DIR/wordpress" . || true

    echo -e "${GREEN}✅ Đã sao lưu website vào: $ARCHIVE_DIR${NC}"
  fi

  # 🛑 Dừng container
  cd "$SITE_DIR"
  docker compose down
  cd "$BASE_DIR"

  # 🧹 Xóa entry override trước khi xoá thư mục
  OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
  MOUNT_ENTRY="      - ../../sites/$site_name/wordpress:/var/www/$site_name"
  MOUNT_LOGS="      - ../../sites/$site_name/logs:/var/www/logs/$site_name"
  if [ -f "$OVERRIDE_FILE" ]; then
    temp_file=$(mktemp)
    grep -vF "$MOUNT_ENTRY" "$OVERRIDE_FILE" | grep -vF "$MOUNT_LOGS" > "$temp_file"
    mv "$temp_file" "$OVERRIDE_FILE"
    echo -e "${GREEN}✅ Đã xóa entry website khỏi docker-compose.override.yml.${NC}"
  fi

  # 🗂️ Xoá thư mục website
  remove_directory "$SITE_DIR"
  echo -e "${GREEN}✅ Đã xoá thư mục website: $SITE_DIR${NC}"

  # 🔐 Xoá chứng chỉ SSL
  remove_file "$SSL_DIR/$DOMAIN.crt"
  remove_file "$SSL_DIR/$DOMAIN.key"
  echo -e "${GREEN}✅ Đã xóa chứng chỉ SSL (nếu có).${NC}"

  # 🗃️ Xoá volume DB
  remove_volume "$MARIADB_VOLUME"
  echo -e "${GREEN}✅ Đã xóa volume DB: $MARIADB_VOLUME${NC}"

  # 🧾 Xoá cấu hình NGINX
  if is_file_exist "$SITE_CONF_FILE"; then
    remove_file "$SITE_CONF_FILE"
    echo -e "${GREEN}✅ Đã xóa file cấu hình NGINX.${NC}"
  fi

  # 🕒 Xoá cronjob nếu có
  if crontab -l 2>/dev/null | grep -q "$site_name"; then
    tmp_cron=$(mktemp)
    crontab -l | grep -v "$site_name" > "$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"
    echo -e "${GREEN}✅ Đã xóa cronjob liên quan đến site.${NC}"
  fi

  # 🔁 Khởi động lại NGINX Proxy
  nginx_restart
  echo -e "${GREEN}✅ Website '$site_name' đã được xoá hoàn toàn.${NC}"
}
