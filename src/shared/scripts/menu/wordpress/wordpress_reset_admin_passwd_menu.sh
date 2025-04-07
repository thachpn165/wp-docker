#!/bin/bash
# === Load config & wordpress_loader.sh ===
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

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# 📋 Hiển thị danh sách website để chọn (dùng select_website)
select_website
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} No website selected.${NC}"
  exit 1
fi

SITE_DIR="$SITES_DIR/$domain"
PHP_CONTAINER="$domain-php"

# 📋 Lấy danh sách tài khoản Admin
echo -e "${YELLOW}📋 Danh sách tài khoản Admin:${NC}"
#docker exec -u "$PHP_USER" "$PHP_CONTAINER" wp user list --role=administrator --fields=ID,user_login --format=table --path=/var/www/html
bash $CLI_DIR/wordpress_wp_cli.sh --domain="${domain}" -- user list --role=administrator --fields=ID,user_login --format=table
echo ""
read -p "Nhập ID của tài khoản cần reset mật khẩu: " user_id

# Truyền tham số vào CLI
bash "$SCRIPTS_DIR/cli/wordpress_reset_admin_passwd.sh" --domain="$domain" --user_id="$user_id"
