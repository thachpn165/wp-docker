#!/bin/bash

# =====================================
# ❌ uninstall.sh – Gỡ cài đặt WP Docker LEMP hoàn toàn khỏi hệ thống
# =====================================

set -euo pipefail
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

BACKUP_DIR="$BASE_DIR/archives/backups_before_remove"
TMP_BACKUP_DIR="$BASE_DIR/tmp"

# 💬 Xác nhận hành động từ người dùng
confirm_action() {
  read -rp "❓ Bạn có muốn sao lưu lại toàn bộ website trước khi xoá không? [y/N]: " confirm
  [[ "$confirm" == "y" || "$confirm" == "Y" ]]
}

# 🔍 Quét danh sách site từ thư mục sites
get_site_list() {
  find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

# 💾 Backup toàn bộ site thủ công vào backup_before_remove
backup_all_sites() {
  echo -e "${CYAN}💾 Đang sao lưu toàn bộ site vào $BACKUP_DIR...${NC}"
  mkdir -p "$BACKUP_DIR"

  for site in $(get_site_list); do
    echo -e "${BLUE}📦 Backup site: $site${NC}"

    site_path="$SITES_DIR/$site"
    env_file="$site_path/.env"
    wordpress_dir="$site_path/wordpress"
    backup_target_dir="$BACKUP_DIR/$site"
    mkdir -p "$backup_target_dir"

    if [[ ! -f "$env_file" ]]; then
      echo -e "${RED}❌ Bỏ qua site '$site': không tìm thấy file .env${NC}"
      continue
    fi

    # Lấy thông tin DB từ file .env
    DB_NAME=$(grep '^MYSQL_DATABASE=' "$env_file" | cut -d '=' -f2)
    DB_USER=$(grep '^MYSQL_USER=' "$env_file" | cut -d '=' -f2)
    DB_PASS=$(grep '^MYSQL_PASSWORD=' "$env_file" | cut -d '=' -f2)

    if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
      echo -e "${RED}❌ Không thể lấy thông tin database từ .env, bỏ qua site '$site'${NC}"
      continue
    fi

    # Backup database
    db_backup_file="$backup_target_dir/${site}_db.sql"
    echo -e "${YELLOW}📦 Đang backup database: $DB_NAME${NC}"
    docker exec "${site}-mariadb" sh -c "exec mysqldump -u$DB_USER -p\"$DB_PASS\" $DB_NAME" > "$db_backup_file" || {
      echo -e "${RED}❌ Lỗi khi backup database cho site '$site'${NC}"
      continue
    }

    # Backup mã nguồn
    echo -e "${YELLOW}📦 Đang nén mã nguồn WordPress...${NC}"
    tar -czf "$backup_target_dir/${site}_wordpress.tar.gz" -C "$wordpress_dir" . || {
      echo -e "${RED}❌ Lỗi khi nén mã nguồn cho site '$site'${NC}"
      continue
    }

    echo -e "${GREEN}✅ Backup site '$site' hoàn tất tại: $backup_target_dir${NC}"
  done
}

# 🧹 Xoá container chính
remove_core_containers() {
  echo -e "${YELLOW}🧹 Đang xoá các container chính: nginx-proxy và redis-cache...${NC}"
  docker rm -f "$NGINX_PROXY_CONTAINER" redis-cache 2>/dev/null || true
}

# 🧹 Xoá toàn bộ container và volume liên quan tới từng site
remove_site_containers() {
  for site in $(get_site_list); do
    echo -e "${YELLOW}🧨 Đang xoá container cho site: $site${NC}"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}

# 🧨 Xoá toàn bộ thư mục trừ backup
remove_all_except_backup() {
  echo -e "${MAGENTA}🗑️  Đang xoá toàn bộ hệ thống trừ thư mục backup_before_remove...${NC}"
  for item in "$BASE_DIR"/*; do
    [[ "$item" == "$BACKUP_DIR" ]] && continue
    rm -rf "$item"
  done
}

# 🧾 Hiển thị container còn lại sau khi xoá
show_remaining_containers() {
  echo -e "\n${CYAN}📋 Danh sách container còn lại sau khi gỡ cài đặt:${NC}"
  remaining=$(docker ps -a --format '{{.Names}}')
  if [[ -z "$remaining" ]]; then
    echo -e "${GREEN}✅ Không còn container Docker nào.${NC}"
  else
    docker ps -a
    echo -e "\n${YELLOW}💡 Nếu bạn muốn xoá hết container còn sót lại, hãy chạy các lệnh sau:${NC}"
    echo "$remaining" | while read -r name; do
      echo "docker stop $name && docker rm $name"
    done
  fi
}

# ================================
# 🚀 Tiến trình chính
# ================================

echo -e "${RED}⚠️ CẢNH BÁO: Script này sẽ xoá toàn bộ hệ thống WP Docker LEMP!${NC}"
echo "Bao gồm toàn bộ site, container, volume, mã nguồn, SSL, cấu hình."

if confirm_action; then
  backup_all_sites
else
  echo -e "${YELLOW}⏩ Bỏ qua bước sao lưu.${NC}"
fi

remove_core_containers
remove_site_containers
remove_all_except_backup

echo -e "\n${GREEN}✅ Đã gỡ cài đặt toàn bộ hệ thống. Backup (nếu có) nằm trong: $BACKUP_DIR${NC}"

show_remaining_containers