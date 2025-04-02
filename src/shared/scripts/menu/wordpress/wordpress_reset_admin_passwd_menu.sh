#!/bin/bash
# === Load config & website_loader.sh ===
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


# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể reset mật khẩu Admin:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}${CROSSMARK} Không có website nào để reset mật khẩu.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần reset mật khẩu: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
PHP_CONTAINER="$site_name-php"

# **Lấy danh sách tài khoản Admin**
echo -e "${YELLOW}📋 Danh sách tài khoản Admin:${NC}"
docker exec -u "$PHP_USER" "$PHP_CONTAINER" wp user list --role=administrator --fields=ID,user_login --format=table --path=/var/www/html

echo ""
read -p "Nhập ID của tài khoản cần reset mật khẩu: " user_id

# Truyền tham số vào CLI
bash "$SCRIPTS_DIR/cli/wordpress_reset_admin_passwd.sh" --site_name="$site_name" --user_id="$user_id"
