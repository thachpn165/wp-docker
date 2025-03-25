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

BACKUP_DIR="$PROJECT_ROOT/backup_before_remove"
TMP_BACKUP_DIR="$PROJECT_ROOT/tmp"

# 💬 Xác nhận hành động từ người dùng
confirm_action() {
  read -rp "❓ Bạn có muốn sao lưu lại toàn bộ website trước khi xoá không? [y/N]: " confirm
  [[ "$confirm" == "y" || "$confirm" == "Y" ]]
}

# 💾 Backup toàn bộ site về tmp rồi chuyển vào backup_before_remove
backup_all_sites() {
  echo -e "${CYAN}💾 Đang sao lưu toàn bộ site vào $BACKUP_DIR...${NC}"
  mkdir -p "$BACKUP_DIR"
  for site in $(get_site_list); do
    echo -e "${BLUE}📦 Backup site: $site${NC}"
    bash "$FUNCTIONS_DIR/backup-manager/backup_website.sh" "$site" "$TMP_BACKUP_DIR/$site"
    mkdir -p "$BACKUP_DIR/$site"
    mv "$TMP_BACKUP_DIR/$site"/* "$BACKUP_DIR/$site/" 2>/dev/null || true
  done
  rm -rf "$TMP_BACKUP_DIR"
}

# 🧨 Xoá toàn bộ thư mục trừ backup
remove_all_except_backup() {
  echo -e "${MAGENTA}🗑️  Đang xoá toàn bộ hệ thống trừ thư mục backup_before_remove...${NC}"
  for item in "$PROJECT_ROOT"/*; do
    [[ "$item" == "$BACKUP_DIR" ]] && continue
    rm -rf "$item"
  done
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
