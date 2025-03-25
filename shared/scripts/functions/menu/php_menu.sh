#!/bin/bash

# =====================================
# 💡 php_menu.sh – Menu quản lý PHP cho website WordPress
# =====================================

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
export PROJECT_ROOT
source "$FUNCTIONS_DIR/php/php_choose_version.sh"
source "$FUNCTIONS_DIR/php/php_change_version.sh"
source "$FUNCTIONS_DIR/php/php_edit_conf.sh"
source "$FUNCTIONS_DIR/php/php_edit_phpini.sh"
source "$FUNCTIONS_DIR/php/php_rebuild.sh"


# 📋 Menu chính quản lý PHP
php_menu() {
  while true; do
    clear
    echo -e "${CYAN}===== QUẢN LÝ PHIÊN BẢN PHP =====${NC}"
    echo -e "${GREEN}[1]${NC} 🔀 Thay đổi phiên bản PHP"
    echo -e "${GREEN}[2]${NC} 🔁 Rebuild container PHP"
    echo -e "${GREEN}[3]${NC} ⚙️  Sửa file php-fpm.conf"
    echo -e "${GREEN}[4]${NC} 🛠️  Sửa file php.ini"
    echo -e "${GREEN}[5]${NC} ⬅️ Quay lại"
    echo ""

    read -p "Chọn một chức năng (1-5): " choice
    case $choice in
      1) php_change_version; read -p "Nhấn Enter để tiếp tục..." ;;
      2) rebuild_php_container; read -p "Nhấn Enter để tiếp tục..." ;;
      3) edit_php_fpm_conf; read -p "Nhấn Enter để tiếp tục..." ;;
      4) edit_php_ini; read -p "Nhấn Enter để tiếp tục..." ;;
      5) break ;;
      *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}"; sleep 2 ;;
    esac
  done
}
